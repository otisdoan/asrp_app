import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:signalr_netcore/signalr_client.dart';

import 'store_detail_page.dart';
import 'order_detail_page.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/chat_storage_service.dart';
import '../../../providers/chat_cart_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/chat_history_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/branch_model.dart';
import '../../../providers/branch_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../core/utils/search_utils.dart';

// ── chat_ai sub-components ──────────────────────────────────────────────────
import 'chat_ai/checkout_bar.dart';
import 'chat_ai/cart_details_bottom_sheet.dart';
import 'chat_ai/widgets/chat_bubble.dart';
import 'chat_ai/widgets/bouncing_dots_indicator.dart';
import 'chat_ai/widgets/recommendation_card.dart';
import 'chat_ai/widgets/order_status_notice_card.dart';
import 'chat_ai/widgets/paid_bill_ticket_card.dart';
import 'chat_ai/widgets/ai_welcome_guidance_card.dart';

// ── shared payment widget ───────────────────────────────────────────────────
import '../../widgets/payment/inline_qr_payment_card.dart';

/// Top-level function chạy trong Background Isolate để parse dữ liệu lịch sử chat phức tạp
List<Map<String, dynamic>> _parseBackendChatHistory(List<dynamic> list) {
  return list.map((item) {
    if (item is! Map) return null;
    final isUser = item['isUser'] as bool? ?? false;
    final text = item['text']?.toString() ?? '';
    final time = item['time']?.toString() ?? '';

    Map<String, dynamic>? draftMap;
    final rawDraft = item['orderDraft'] ?? item['orderDraftJson'];
    if (rawDraft is Map) {
      draftMap = Map<String, dynamic>.from(rawDraft);
    } else if (rawDraft is String && rawDraft.isNotEmpty) {
      try {
        final parsed = jsonDecode(rawDraft);
        if (parsed is Map) draftMap = Map<String, dynamic>.from(parsed);
      } catch (_) {}
    }

    Map<String, dynamic>? dataMap;
    if (draftMap?['data'] is Map) {
      dataMap = Map<String, dynamic>.from(draftMap!['data']);
    } else if (draftMap?['Data'] is Map) {
      dataMap = Map<String, dynamic>.from(draftMap!['Data']);
    }

    String? messageType = draftMap?['messageType'] ?? draftMap?['MessageType'] ?? dataMap?['messageType'] ?? dataMap?['MessageType'] ?? item['messageType'];
    String? orderStatus = draftMap?['orderStatus'] ?? draftMap?['OrderStatus'] ?? draftMap?['status'] ?? draftMap?['Status'] ?? dataMap?['status'] ?? dataMap?['Status'] ?? dataMap?['orderStatus'] ?? dataMap?['OrderStatus'] ?? item['orderStatus'];
    String? orderId = draftMap?['orderId'] ?? draftMap?['OrderId'] ?? dataMap?['orderId'] ?? dataMap?['OrderId'] ?? item['orderId'];

    bool isPaidStatus = orderStatus?.toLowerCase() == 'paid' || orderStatus?.toLowerCase() == 'completed';
    bool isPaidBill = messageType == 'PAYMENT_SUCCESS' || draftMap?['isPaidBill'] == true || dataMap?['isPaidBill'] == true || item['isPaidBill'] == true || isPaidStatus;
    double? amountVal = (draftMap?['amount'] as num?)?.toDouble() ?? (draftMap?['Amount'] as num?)?.toDouble() ?? (dataMap?['amount'] as num?)?.toDouble() ?? (dataMap?['Amount'] as num?)?.toDouble() ?? (item['amount'] as num?)?.toDouble();

    final orderPreview = item['orderPreview'] ?? draftMap?['orderPreview'] ?? draftMap?['OrderPreview'] ?? dataMap?['orderPreview'];
    final resolvedItems = item['resolvedItems'] ?? draftMap?['resolvedItems'] ?? draftMap?['ResolvedItems'] ?? dataMap?['resolvedItems'];
    final qrCode = item['qrCode'] ?? draftMap?['qrCode'] ?? draftMap?['QrCode'] ?? dataMap?['qrCode'];
    final storeName = item['storeName'] ?? draftMap?['storeName'] ?? draftMap?['StoreName'] ?? dataMap?['storeName'] ?? (orderPreview is Map ? orderPreview['store_name'] : null);
    final items = item['items'] ?? draftMap?['items'] ?? draftMap?['Items'] ?? dataMap?['items'] ?? resolvedItems;
    final secondsRemaining = item['secondsRemaining'] ?? draftMap?['secondsRemaining'] ?? 300;

    final rawTimeVal = item['updatedAt'] ?? item['createdAt'] ?? item['timestamp'] ?? draftMap?['createdAt'] ?? dataMap?['createdAt'];

    return {
      'id': item['id']?.toString() ?? orderId ?? '${time}_${text.hashCode}',
      'isUser': isUser,
      'text': text,
      'time': time,
      'updatedAt': rawTimeVal,
      'createdAt': rawTimeVal,
      'orderDraft': item['orderDraft'] ?? draftMap,
      'orderPreview': orderPreview,
      'resolvedItems': resolvedItems,
      'qrCode': isPaidBill ? null : qrCode,
      'storeName': storeName,
      'items': items,
      'secondsRemaining': secondsRemaining,
      'messageType': messageType,
      'orderStatus': orderStatus,
      'orderId': orderId,
      'isPaidBill': isPaidBill,
      'amount': amountVal,
      'recommendations': item['recommendations'],
      'branchRecommendations': item['branchRecommendations'],
      'showChips': false,
    };
  }).whereType<Map<String, dynamic>>().toList();
}



class ChatAssistantPage extends ConsumerStatefulWidget {
  const ChatAssistantPage({super.key});

  @override
  ConsumerState<ChatAssistantPage> createState() =>
      _ChatAssistantPageState();
}

class _ChatAssistantPageState extends ConsumerState<ChatAssistantPage> {
  // ── State ──────────────────────────────────────────────────────────────────
  late final String _sessionId = 'session_default_user';
  final ChatStorageService _chatStorageService = ChatStorageService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  OverlayEntry? _activeOverlayEntry;
  Position? _userPosition;
  HubConnection? _hubConnection;
  Timer? _pollingTimer;
  DateTime? _selectedPickupTime;
  bool _isNavigatingToSuccess = false;
  bool _showGuidanceCard = false;

  int _displayedMessagesCount = 15;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _scrollController.addListener(_onScrollListener);

    // Tự động lắng nghe mọi thay đổi của chatHistoryProvider để đồng bộ xuống SharedPreferences
    ref.listenManual(chatHistoryProvider, (previous, next) {
      if (next.isNotEmpty) {
        _chatStorageService.saveChatHistory(_sessionId, next);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 1. Tải tức thì từ RAM / Local Storage để render ngay không cần chờ reload
      final currentInMemory = ref.read(chatHistoryProvider);
      if (currentInMemory.length <= 1) {
        final cachedHistory = await _chatStorageService.loadChatHistory(_sessionId);
        if (cachedHistory != null && cachedHistory.isNotEmpty) {
          ref.read(chatHistoryProvider.notifier).state = cachedHistory;
        }
      }
      
      // Cuộn xuống cuối ngay lập tức để người dùng xem tin nhắn mới nhất
      _scrollToBottom();

      // 2. Đồng bộ ngầm ở Background (Silent Background Sync) không làm nảy/reload UI
      ref.read(orderProvider.notifier).fetchMyOrders().then((_) {
        if (mounted) _syncExistingOrderStatuses();
      });

      _loadChatHistory();

      _initSignalR("");

      _pollingTimer?.cancel();
      _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (mounted) {
          ref.read(orderProvider.notifier).fetchMyOrders().then((_) {
            if (mounted) _syncExistingOrderStatuses();
          });
        }
      });
    });
  }

  Future<void> _loadChatHistory() async {
    try {
      final response = await DioClient()
          .dio
          .get('/ai/chat/history',
              queryParameters: {'sessionId': _sessionId});
      final rawData = response.data;
      final List<dynamic> list = rawData is List<dynamic>
          ? rawData
          : (rawData is Map && rawData['data'] is List<dynamic>
              ? rawData['data'] as List<dynamic>
              : []);
      if (list.isNotEmpty) {
        final loadedMessages = await compute(_parseBackendChatHistory, list);

        // Bảo toàn dữ liệu isPaidBill từ cache hiện tại và orderProvider
        final currentHistory = ref.read(chatHistoryProvider);
        final orders = ref.read(orderProvider);

        final mergedMessages = loadedMessages.map((m) {
          final orderId = m['orderId']?.toString();
          if (orderId != null && orderId.isNotEmpty) {
            final existingPaidMsg = currentHistory.firstWhere(
              (curr) => curr['orderId']?.toString().toLowerCase() == orderId.toLowerCase() && curr['isPaidBill'] == true,
              orElse: () => <String, dynamic>{},
            );
            final orderInRepo = orders.firstWhere(
              (o) => o.id.toLowerCase() == orderId.toLowerCase(),
              orElse: () => MockOrder(
                id: '',
                storeName: '',
                items: [],
                totalAmount: 0,
                status: MockOrderStatus.pendingConfirm,
                orderTime: DateTime.now(),
                pickupTime: DateTime.now(),
                originalMinutes: 15,
                timeline: [],
              ),
            );

            bool isPaid = existingPaidMsg['isPaidBill'] == true || (orderInRepo.id.isNotEmpty && orderInRepo.isPaid);
            if (isPaid) {
              final storeName = m['storeName'] ?? existingPaidMsg['storeName'] ?? (orderInRepo.id.isNotEmpty ? orderInRepo.storeName : null);
              final amount = m['amount'] ?? existingPaidMsg['amount'] ?? (orderInRepo.id.isNotEmpty ? orderInRepo.totalAmount.toDouble() : null);
              final items = m['items'] ?? existingPaidMsg['items'] ?? (orderInRepo.id.isNotEmpty ? orderInRepo.items.map((i) => {
                'menu_item_name': i.name,
                'quantity': i.quantity,
                'price': i.price.toDouble(),
              }).toList() : null);
              final updatedAt = existingPaidMsg['updatedAt'] ?? (orderInRepo.id.isNotEmpty ? orderInRepo.orderTime : m['updatedAt']);

              return {
                ...m,
                'isPaidBill': true,
                'qrCode': null,
                if (storeName != null) 'storeName': storeName,
                if (amount != null) 'amount': amount,
                if (items != null) 'items': items,
                if (updatedAt != null) 'updatedAt': updatedAt,
              };
            }
          }
          return m;
        }).toList();

        // Preserve any local messages (such as standalone PaidBillTicketCard or ORDER_TRACKING messages)
        // that were in currentHistory but NOT present in loadedMessages array!
        final localOnlyMessages = currentHistory.where((curr) {
          final isLocalSpecial = curr['isPaidBill'] == true || curr['messageType'] == 'ORDER_TRACKING' || curr['messageType'] == 'PAYMENT_SUCCESS';
          if (!isLocalSpecial) return false;
          final currId = curr['id']?.toString() ?? curr['orderId']?.toString();
          if (currId == null || currId.isEmpty) return true;
          return !mergedMessages.any((m) => (m['id']?.toString() == currId) || (m['orderId']?.toString() == currId && m['isPaidBill'] == true));
        }).toList();

        final finalMergedList = [...mergedMessages, ...localOnlyMessages];

        // 🛡️ Sort paid bills strictly by full DateTime (Date + Time) ascending:
        // Older bill (đặt trước e.g. 18/08 20:56) TOP/FIRST, newly placed bill (mới đặt e.g. 20/08 15:48) BOTTOM/AFTER!
        finalMergedList.sort((a, b) {
          final isPaidA = a['isPaidBill'] == true;
          final isPaidB = b['isPaidBill'] == true;
          if (isPaidA && isPaidB) {
            final timeA = parseChatMsgTime(a['updatedAt'] ?? a['createdAt'] ?? a['time']);
            final timeB = parseChatMsgTime(b['updatedAt'] ?? b['createdAt'] ?? b['time']);
            return timeA.compareTo(timeB); // Older Date+Time FIRST (Top)
          }
          return 0;
        });

        ref.read(chatHistoryProvider.notifier).state = finalMergedList;
        await _chatStorageService.saveChatHistory(_sessionId, finalMergedList);
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('[ChatAssistant] Error loading chat history: $e');
    }
  }

  /// Push thông báo cho các đơn hàng đã có status nhưng chưa có trong lịch sử chat,
  /// đồng thời đảm bảo thẻ PaidBillTicketCard luôn được lưu giữ và cập nhật đầy đủ từ orderProvider.
  void _syncExistingOrderStatuses() {
    final rawOrders = ref.read(orderProvider);
    final orders = List<MockOrder>.from(rawOrders);
    // 🛡️ Sort orders by orderTime DESCENDING so newest orders (mới đặt) appear FIRST, older orders (đặt trước) appear AFTER
    orders.sort((a, b) => b.orderTime.compareTo(a.orderTime));

    bool anyPushed = false;

    for (final order in orders) {
      // Chỉ xử lý đơn đã thanh toán hoặc đang hoạt động
      if (!order.isPaid) continue;
      // Bỏ qua đơn hàng quá cũ (hơn 48h)
      if (DateTime.now().difference(order.orderTime).inHours > 48) continue;

      final currentHistory = ref.read(chatHistoryProvider);

      // 1. Đảm bảo tin nhắn hóa đơn đã thanh toán (isPaidBill) tồn tại và cập nhật đầy đủ thông tin từ orderProvider
      final hasPaidBill = currentHistory.any((m) =>
          m['orderId']?.toString().toLowerCase() == order.id.toLowerCase() && m['isPaidBill'] == true);

      if (!hasPaidBill) {
        final existingOrderMsgIndex = currentHistory.indexWhere((m) =>
            m['orderId']?.toString().toLowerCase() == order.id.toLowerCase());
        if (existingOrderMsgIndex != -1) {
          // Nâng cấp tin nhắn đơn hàng hiện có thành PaidBillTicketCard
          ref.read(chatHistoryProvider.notifier).update((chatState) {
            return chatState.map((m) {
              if (m['orderId']?.toString().toLowerCase() == order.id.toLowerCase()) {
                return {
                  ...m,
                  'isPaidBill': true,
                  'qrCode': null,
                  'storeName': order.storeName,
                  'amount': order.totalAmount.toDouble(),
                  'items': order.items.map((i) => {
                    'menu_item_name': i.name,
                    'quantity': i.quantity,
                    'price': i.price.toDouble(),
                  }).toList(),
                  'text': 'Cảm ơn bạn! Đơn hàng đã được thanh toán thành công. Mã QR lấy hàng tại quán của bạn bên dưới:',
                  'updatedAt': order.orderTime,
                };
              }
              return m;
            }).toList();
          });
          anyPushed = true;
        } else {
          // Tạo mới tin nhắn PaidBillTicketCard từ dữ liệu đơn hàng orderProvider
          ref.read(chatHistoryProvider.notifier).update((chatState) {
            final timeStr = '${order.orderTime.hour.toString().padLeft(2, '0')}:${order.orderTime.minute.toString().padLeft(2, '0')}';
            final newPaidMsg = {
              'isUser': false,
              'messageType': 'PAYMENT_SUCCESS',
              'isPaidBill': true,
              'orderId': order.id,
              'amount': order.totalAmount.toDouble(),
              'storeName': order.storeName,
              'items': order.items.map((i) => {
                'menu_item_name': i.name,
                'quantity': i.quantity,
                'price': i.price.toDouble(),
              }).toList(),
              'text': 'Cảm ơn bạn! Dạ em đã nhận được thanh toán. Mã QR lấy hàng tại quán đã sẵn sàng bên dưới nhé!',
              'time': timeStr,
              'updatedAt': order.orderTime,
            };
            return [...chatState, newPaidMsg];
          });
          anyPushed = true;
        }
      }

      // 2. Đẩy thông báo trạng thái đơn hàng (ORDER_TRACKING) nếu chưa có
      String statusMsgText = '';
      String rawStatusStr = '';
      switch (order.status) {
        case MockOrderStatus.pendingConfirm:
          statusMsgText = '⏳ Quán đã nhận thông tin đơn và đang kiểm tra.';
          rawStatusStr = 'PendingConfirmation';
          break;
        case MockOrderStatus.preparing:
          statusMsgText = '👨‍🍳 Bếp đang chế biến món ăn của bạn.';
          rawStatusStr = 'Preparing';
          break;
        case MockOrderStatus.ready:
          statusMsgText = '🔔 Món ăn đã chuẩn bị xong! Mời bạn đến nhận món tại quầy.';
          rawStatusStr = 'ReadyForPickup';
          break;
        case MockOrderStatus.completed:
          statusMsgText = '🎉 Đơn hàng đã hoàn thành. Cảm ơn bạn!';
          rawStatusStr = 'Completed';
          break;
        case MockOrderStatus.cancelled:
          statusMsgText = '❌ Đơn hàng đã được hủy.';
          rawStatusStr = 'Cancelled';
          break;
      }

      if (statusMsgText.isEmpty) continue;

      final updatedHistory = ref.read(chatHistoryProvider);
      final alreadyExists = updatedHistory.any((m) =>
          m['orderId'] == order.id && m['orderStatus'] == rawStatusStr);
      if (alreadyExists) continue;

      ref.read(chatHistoryProvider.notifier).update((chatState) {
        final dup = chatState.any((m) =>
            m['orderId'] == order.id && m['orderStatus'] == rawStatusStr);
        if (dup) return chatState;

        final newMsg = {
          'isUser': false,
          'messageType': 'ORDER_TRACKING',
          'orderId': order.id,
          'orderStatus': rawStatusStr,
          'text': statusMsgText,
          'time': '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
          'updatedAt': DateTime.now(),
        };
        return [...chatState, newMsg];
      });
      anyPushed = true;
    }

    if (anyPushed) _scrollToBottom();
  }

  void _onScrollListener() {
    if (_scrollController.hasClients && _scrollController.position.pixels <= 100) {
      final total = ref.read(chatHistoryProvider).length;
      if (_displayedMessagesCount < total) {
        setState(() {
          _displayedMessagesCount = (_displayedMessagesCount + 15).clamp(0, total);
        });
      }
    }
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
              await _chatStorageService.clearChatHistory(_sessionId);
              final now = DateTime.now();
              final timeStr =
                  '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
              final initialMsgs = [
                {
                  'isUser': false,
                  'text':
                      'Xin chào! Tôi là trợ lý ảo AI DineX. Tôi có thể giúp gì cho bạn hôm nay?',
                  'time': timeStr,
                  'showChips': true,
                }
              ];
              ref.read(chatHistoryProvider.notifier).state = initialMsgs;
              await _chatStorageService.saveChatHistory(_sessionId, initialMsgs);
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
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
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

  void _sendMessage([String? text]) {
    final msgText = (text != null && text.trim().isNotEmpty) ? text : _textController.text;
    _handleSubmitted(msgText);
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
    bool isValidGuid(String id) {
      return RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(id);
    }

    String branchId = '';

    if (chatCart.isNotEmpty && isValidGuid(chatCart.first.branchId)) {
      branchId = chatCart.first.branchId;
    } else {
      for (final bCart in mainCart.carts.values) {
        if (bCart.items.isNotEmpty && bCart.branchId != null && isValidGuid(bCart.branchId!)) {
          branchId = bCart.branchId!;
          break;
        }
      }
    }

    if (branchId.isEmpty) {
      final branches = ref.read(branchesFutureProvider).asData?.value ?? [];
      for (final b in branches) {
        if (isValidGuid(b.id)) {
          branchId = b.id;
          break;
        }
      }
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
              'content': m['text']?.toString() ?? '',
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

      final rawData = response.data;
      final Map<String, dynamic> data = rawData is Map<String, dynamic>
          ? (rawData['data'] is Map<String, dynamic>
              ? rawData['data'] as Map<String, dynamic>
              : rawData)
          : {};

      final replyTime = DateTime.now();
      final replyTimeStr =
          '${replyTime.hour.toString().padLeft(2, '0')}:${replyTime.minute.toString().padLeft(2, '0')}';

      String replyText = data['reply']?.toString() ?? 'Xin lỗi, hệ thống đang gặp sự cố.';
      dynamic orderDraft = data['orderDraft'];
      dynamic orderPreview = data['orderDraftPreview'];
      dynamic resolvedItems = data['resolvedItems'];
      List<dynamic>? branchRecs = data['branchRecommendations'] as List<dynamic>?;
      List<dynamic>? recommendations = data['recommendations'] as List<dynamic>?;

      // 1. Ingredient & Recipe Availability Check:
      // If item in resolvedItems or orderDraft has missing recipe/ingredients or is unavailable, cancel orderDraft.
      bool isIngredientsAvailable = true;
      if (resolvedItems is List && resolvedItems.isNotEmpty) {
        for (final item in resolvedItems) {
          if (item is Map) {
            if (item['hasRecipe'] == false || item['isAvailable'] == false || item['stock'] == 0 || item['hasIngredients'] == false) {
              isIngredientsAvailable = false;
              break;
            }
          }
        }
      }
      if (!isIngredientsAvailable) {
        orderDraft = null;
        orderPreview = null;
        resolvedItems = null;
        replyText = 'Rất tiếc, món ăn bạn yêu cầu hiện đang thiếu nguyên liệu hoặc chưa được thiết lập công thức chế biến. Bạn vui lòng chọn món khác nhé!';
      }

      // 2. Distance Calculation & 15km Nearby Radius Filtering via LocationService
      final userLocation = ref.read(userLocationProvider) ?? _userPosition;
      final branchesAsync = ref.read(branchesFutureProvider);
      final List<BranchListItemModel> branches = branchesAsync.asData?.value ?? [];

      bool hasNearbyStoresForQuery = true;
      if (branchRecs != null && branchRecs.isNotEmpty) {
        final List<dynamic> processedRecs = [];
        final List<dynamic> nearbyRecs = [];

        for (final item in branchRecs) {
          if (item is Map) {
            final String bId = item['branchId']?.toString() ?? item['branch_id']?.toString() ?? '';
            final String sName = item['storeName']?.toString() ?? item['branchName']?.toString() ?? item['name']?.toString() ?? '';

            BranchListItemModel? matchedBranch;
            if (bId.isNotEmpty) {
              for (final b in branches) {
                if (b.id == bId) { matchedBranch = b; break; }
              }
            }
            if (matchedBranch == null && sName.isNotEmpty) {
              for (final b in branches) {
                final bName = b.name.toLowerCase();
                final queryName = sName.toLowerCase();
                if (bName.contains(queryName) || queryName.contains(bName)) {
                  matchedBranch = b; break;
                }
              }
            }

            final double? lat = matchedBranch?.latitude ?? (item['latitude'] as num?)?.toDouble() ?? (item['lat'] as num?)?.toDouble();
            final double? lon = matchedBranch?.longitude ?? (item['longitude'] as num?)?.toDouble() ?? (item['lng'] as num?)?.toDouble();
            final String address = matchedBranch?.address ?? item['address']?.toString() ?? item['branchAddress']?.toString() ?? '';
            final String realStoreName = matchedBranch?.name ?? sName;

            final String distStr = LocationService.calculateBranchDistance(
              userLocation: userLocation,
              branchLat: lat,
              branchLng: lon,
              branchAddress: address,
              branchName: realStoreName,
            );

            final double distKm = LocationService.calculateDistanceInKm(
              userLocation: userLocation,
              branchLat: lat,
              branchLng: lon,
              branchAddress: address,
              branchName: realStoreName,
            );

            final updatedItem = {
              ...item,
              if (lat != null) 'latitude': lat,
              if (lon != null) 'longitude': lon,
              'storeName': realStoreName,
              'address': address,
              'distance': distStr,
              'distanceKm': distKm,
            };

            processedRecs.add(updatedItem);
            if (distKm <= 15.0) {
              nearbyRecs.add(updatedItem);
            }
          } else {
            processedRecs.add(item);
          }
        }

        // 🛡️ Sort both lists by distanceKm ascending so closest stores are ALWAYS listed first!
        processedRecs.sort((a, b) {
          if (a is! Map || b is! Map) return 0;
          final double distA = (a['distanceKm'] as num?)?.toDouble() ?? 999999.0;
          final double distB = (b['distanceKm'] as num?)?.toDouble() ?? 999999.0;
          return distA.compareTo(distB);
        });

        nearbyRecs.sort((a, b) {
          if (a is! Map || b is! Map) return 0;
          final double distA = (a['distanceKm'] as num?)?.toDouble() ?? 999999.0;
          final double distB = (b['distanceKm'] as num?)?.toDouble() ?? 999999.0;
          return distA.compareTo(distB);
        });

        if (nearbyRecs.isNotEmpty) {
          branchRecs = nearbyRecs;
        } else {
          hasNearbyStoresForQuery = false;
          branchRecs = processedRecs; // Fallback to bestsellers with real distance sorted closest first!
        }
      }

      // 3. Strict Fuzzy Query Matching (e.g. 'pho' matches 'phở', not 'chè'):
      bool isMatchFound = true;
      if (branchRecs != null && branchRecs.isNotEmpty) {
        final matchingRecs = branchRecs.where((item) {
          if (item is! Map) return false;
          final dishName = item['dishName']?.toString() ?? item['name']?.toString() ?? '';
          return SearchUtils.isStrictQueryMatch(text, dishName);
        }).toList();

        if (matchingRecs.isNotEmpty) {
          branchRecs = matchingRecs;
        } else {
          isMatchFound = false;
        }
      } else {
        isMatchFound = false;
      }

      // 4. Formulate Fallback Prompt:
      if (!hasNearbyStoresForQuery && (orderDraft == null || !isIngredientsAvailable)) {
        replyText = 'Ở gần bạn (trong bán kính 15km) hiện không có món nào tương tự "$text". Dưới đây là một số món gợi ý khác bạn có thể tham khảo:';
        orderDraft = null;
        orderPreview = null;
      } else if (!isMatchFound && (orderDraft == null || !isIngredientsAvailable)) {
        replyText = 'Hiện tại hệ thống chưa tìm thấy món "$text" phù hợp với yêu cầu của bạn. Tuy nhiên, đây là một số món gợi ý ngon có thể bạn sẽ thích:';
        orderDraft = null;
        orderPreview = null;
      }

      ref.read(chatHistoryProvider.notifier).update((state) => [
            ...state,
            {
              'isUser': false,
              'text': replyText,
              'time': replyTimeStr,
              'orderPreview': orderPreview,
              'orderDraft': orderDraft,
              'resolvedItems': resolvedItems,
              'recommendations': recommendations,
              'branchRecommendations': branchRecs,
              'showChips': true,
            }
          ]);

      setState(() => _isTyping = false);
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      if (e is DioException) {
        debugPrint('[ChatAssistant] DioError 400: ${e.response?.statusCode}');
        debugPrint('[ChatAssistant] Response details: ${e.response?.data}');
      } else {
        debugPrint('[ChatAssistant] Error calling AI chat: $e');
      }

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

  // ignore: unused_element
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

      final rawCreateData = createOrderResponse.data;
      final Map<String, dynamic> createOrderData = rawCreateData is Map<String, dynamic>
          ? (rawCreateData['data'] is Map<String, dynamic> ? rawCreateData['data'] as Map<String, dynamic> : rawCreateData)
          : {};
      final orderId = createOrderData['id']?.toString() ?? '';

      final paymentResponse = await DioClient().dio.post(
        '/orders/$orderId/payments',
        data: {
          'method': 1,
          'note': 'Thanh toan don hang dat qua AI Chat',
        },
      );

      final rawPaymentData = paymentResponse.data;
      final Map<String, dynamic> paymentData = rawPaymentData is Map<String, dynamic>
          ? (rawPaymentData['data'] is Map<String, dynamic> ? rawPaymentData['data'] as Map<String, dynamic> : rawPaymentData)
          : {};
      final checkoutUrl = paymentData['checkoutUrl'] as String? ?? '';
      final qrCode = paymentData['qrCode'] as String? ?? '';
      final double amount =
          (paymentData['amount'] as num?)?.toDouble() ?? 0.0;

      if (mounted) Navigator.pop(context);

      final now = DateTime.now();
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      // Disable any previous active QR codes in history so user sees only the newest QR card
      ref.read(chatHistoryProvider.notifier).update((state) {
        final disabledOld = state.map((m) {
          if (m['qrCode'] != null) {
            return {...m, 'qrCode': null, 'orderId': null};
          }
          return m;
        }).toList();
        return [
          ...disabledOld,
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
        ];
      });

      _initSignalR(orderId);
      _startInlinePaymentPolling(orderId);
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint('[AI Checkout Error]: $e');
      String checkoutErrorMsg =
          'Không thể khởi tạo thanh toán đơn hàng. Vui lòng thử lại.';
      if (e is DioException && e.response?.data is Map<String, dynamic>) {
        final errMap = e.response!.data as Map<String, dynamic>;
        final detail =
            errMap['detail'] ?? errMap['Detail'] ?? errMap['message'] ?? errMap['Message'];
        if (detail != null && detail.toString().isNotEmpty) {
          checkoutErrorMsg = detail.toString();
        }
      }
      if (mounted) {
        _showTopNotification(
          checkoutErrorMsg,
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

    // 🛡️ 15km Distance Check before generating QR code / submitting order
    final userLocation = ref.read(userLocationProvider) ?? _userPosition;
    final branchesAsync = ref.read(branchesFutureProvider);
    final List<BranchListItemModel> branches = branchesAsync.asData?.value ?? [];

    final String targetBranchId = cart.first.branchId;
    final String targetStoreName = '';

    BranchListItemModel? matchedBranch;
    if (targetBranchId.isNotEmpty) {
      for (final b in branches) {
        if (b.id == targetBranchId) {
          matchedBranch = b;
          break;
        }
      }
    }
    if (matchedBranch == null && targetStoreName.isNotEmpty) {
      for (final b in branches) {
        final bName = b.name.toLowerCase();
        final sName = targetStoreName.toLowerCase();
        if (bName.contains(sName) || sName.contains(bName)) {
          matchedBranch = b;
          break;
        }
      }
    }

    final double? lat = matchedBranch?.latitude;
    final double? lon = matchedBranch?.longitude;
    final String address = matchedBranch?.address ?? '';
    final String realStoreName = matchedBranch?.name ?? targetStoreName;

    final double distKm = LocationService.calculateDistanceInKm(
      userLocation: userLocation,
      branchLat: lat,
      branchLng: lon,
      branchAddress: address,
      branchName: realStoreName,
    );

    if (distKm > 15.0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cửa hàng ở quá xa',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            'Rất tiếc, cửa hàng "$realStoreName" cách vị trí nhận hàng của bạn quá xa (${distKm.toStringAsFixed(1)}km > bán kính 15km phục vụ).\n\nHệ thống không thể tạo mã QR thanh toán cho cửa hàng nằm ngoài bán kính 15km. Bạn vui lòng đổi địa điểm nhận hàng hoặc chọn cửa hàng gần hơn nhé!',
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Đã hiểu',
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEA580C)),
              ),
            ),
          ],
        ),
      );
      return;
    }

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

      final rawResponse = response.data;
      Map<String, dynamic> payloadMap = {};
      if (rawResponse is Map<String, dynamic>) {
        if (rawResponse.containsKey('messageType')) {
          payloadMap = rawResponse;
        } else if (rawResponse['data'] is Map<String, dynamic> &&
            (rawResponse['data'] as Map<String, dynamic>).containsKey('messageType')) {
          payloadMap = rawResponse['data'] as Map<String, dynamic>;
        } else {
          payloadMap = rawResponse;
        }
      }

      final replyTime = DateTime.now();
      final replyTimeStr =
          '${replyTime.hour.toString().padLeft(2, '0')}:${replyTime.minute.toString().padLeft(2, '0')}';

      if (payloadMap['messageType'] == 'PAYMENT_QR') {
        final qrData = payloadMap['data'] is Map<String, dynamic>
            ? payloadMap['data'] as Map<String, dynamic>
            : <String, dynamic>{};

        final newOrderId = qrData['orderId']?.toString() ?? '';
        final qrCodeStr = qrData['qrCode']?.toString() ?? '';
        final double cartTotal = cart.fold(0.0, (sum, i) => sum + (i.effectivePrice * i.quantity));
        final double amountVal = (qrData['amount'] as num?)?.toDouble() ?? cartTotal;
        final String storeName = realStoreName;
        final List<Map<String, dynamic>> itemsList = cart.map((e) => {
          'menu_item_name': e.name,
          'quantity': e.quantity,
          'price': e.effectivePrice,
        }).toList();

        ref.read(chatCartProvider.notifier).clearCart();

        // Disable any previous active QR codes in history so user sees only the newest QR card
        ref.read(chatHistoryProvider.notifier).update((state) {
          final disabledOld = state.map((m) {
            if (m['qrCode'] != null) {
              return {...m, 'qrCode': null, 'orderId': null};
            }
            return m;
          }).toList();
          return [
            ...disabledOld,
            {
              'isUser': false,
              'text':
                  'Đơn hàng của bạn đã được khởi tạo thành công! Vui lòng quét mã QR bên dưới để thanh toán.',
              'time': replyTimeStr,
              'orderId': newOrderId,
              'qrCode': qrCodeStr,
              'amount': amountVal,
              'storeName': storeName,
              'items': itemsList,
              'secondsRemaining': 600,
              'showChips': true,
            }
          ];
        });

        _initSignalR(newOrderId);
        _startInlinePaymentPolling(newOrderId);
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
          final serverDetail =
              errData['detail'] ?? errData['Detail'] ?? errData['title'] ?? errData['Title'];
          final serverMsg = errData['message'] ?? errData['Message'];
          if (serverDetail != null && serverDetail.toString().isNotEmpty) {
            errorMessage = serverDetail.toString();
          } else if (serverMsg != null && serverMsg.toString().isNotEmpty) {
            errorMessage = serverMsg.toString();
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

        if (isPaid) {
          timer.cancel();
          if (mounted) {
            _handlePaymentSuccessSignalR(orderId, 0.0);
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
        _hubConnection!.state == HubConnectionState.Connected) {
      if (orderId.isNotEmpty) {
        try {
          await _hubConnection!.invoke('JoinOrderTracking', args: [orderId]);
          debugPrint('[SignalR] Joined group for order $orderId');
        } catch (e) {
          debugPrint('[SignalR] Error invoking JoinOrderTracking: $e');
        }
      }
      return;
    }

    final hubUrl = ApiConstants.chatAgentHubUrl;
    debugPrint('[SignalR] Connecting to $hubUrl');

    _hubConnection = HubConnectionBuilder()
        .withUrl(hubUrl)
        .withAutomaticReconnect()
        .build();

    _hubConnection!.onreconnecting(({error}) {
      debugPrint('[SignalR] Reconnecting due to network drop: $error');
    });

    _hubConnection!.onreconnected(({connectionId}) {
      debugPrint('[SignalR] Reconnected successfully ($connectionId). Syncing history & re-joining order $orderId');
      if (orderId.isNotEmpty) {
        _hubConnection?.invoke('JoinOrderTracking', args: [orderId]);
      }
      _loadChatHistory();
    });

    _hubConnection!.on('ReceiveAgentMessage', (List<Object?>? args) {
      if (!mounted) return;
      if (args != null && args.isNotEmpty) {
        Map<String, dynamic>? payload;
        final rawArg = args[0];
        if (rawArg is Map) {
          payload = Map<String, dynamic>.from(rawArg);
        } else if (rawArg is String && rawArg.isNotEmpty) {
          try {
            final parsed = jsonDecode(rawArg);
            if (parsed is Map) payload = Map<String, dynamic>.from(parsed);
          } catch (_) {}
        }
        if (payload == null) return;
        debugPrint('[SignalR] Received payload: $payload');

        final msgType = (payload['messageType'] ?? payload['MessageType'])?.toString();
        final data = payload['data'] is Map
            ? Map<String, dynamic>.from(payload['data'] as Map)
            : (payload['Data'] is Map
                ? Map<String, dynamic>.from(payload['Data'] as Map)
                : <String, dynamic>{});

        final receivedOrderId = (data['orderId'] ?? data['OrderId'] ?? payload['orderId'] ?? payload['OrderId'])?.toString();
        final orderStatus = (data['status'] ?? data['Status'] ?? payload['status'] ?? payload['Status'])?.toString() ?? 'PendingConfirmation';
        final amount = (data['amount'] ?? data['Amount'] ?? payload['amount'] ?? payload['Amount'] as num?)?.toDouble() ?? 0.0;

        if (msgType == 'PAYMENT_SUCCESS') {
          if (receivedOrderId != null && receivedOrderId.isNotEmpty) {
            _handlePaymentSuccessSignalR(receivedOrderId, amount);
          }
        } else if (msgType == 'ORDER_TRACKING' || orderStatus.isNotEmpty) {
          String statusMsgText = 'Cập nhật tiến trình đơn hàng';
          switch (orderStatus) {
            case 'PendingConfirmation':
              statusMsgText = '⏳ Quán đã nhận thông tin đơn và đang kiểm tra.';
              break;
            case 'PendingInventory':
              statusMsgText = '📦 Quán đang kiểm tra kho nguyên liệu phục vụ đơn của bạn.';
              break;
            case 'Preparing':
              statusMsgText = '👨‍🍳 Bếp đang chế biến món ăn của bạn.';
              break;
            case 'ReadyForPickup':
              statusMsgText = '🔔 Món ăn đã chuẩn bị xong! Mời bạn đến nhận món tại quầy.';
              break;
            case 'Completed':
              statusMsgText = '🎉 Đơn hàng đã hoàn thành. Cảm ơn bạn!';
              break;
            case 'Cancelled':
              statusMsgText = '❌ Đơn hàng đã được hủy.';
              break;
          }

          if (receivedOrderId != null && receivedOrderId.isNotEmpty) {
            _showTopNotification(statusMsgText, AppColors.primary, Icons.info_outline);
            ref.read(chatHistoryProvider.notifier).update((state) {
              final newMsg = {
                'isUser': false,
                'messageType': 'ORDER_TRACKING',
                'orderId': receivedOrderId,
                'orderStatus': orderStatus,
                'text': statusMsgText,
                'time': '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                'updatedAt': DateTime.now(),
              };
              return [...state, newMsg];
            });
            _scrollToBottom();
          }
        }
      }
    });

    try {
      await _hubConnection!.start();
      if (orderId.isNotEmpty) {
        await _hubConnection!.invoke('JoinOrderTracking', args: [orderId]);
        debugPrint('[SignalR] Connected and joined order $orderId');
      }

      // Auto join tracking for active orders in history
      final history = ref.read(chatHistoryProvider);
      final activeOrderIds = history
          .map((m) => m['orderId']?.toString())
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toSet();
      for (final id in activeOrderIds) {
        try {
          await _hubConnection!.invoke('JoinOrderTracking', args: [id]);
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('[SignalR] Error starting SignalR: $e');
    }
  }

  void _handlePaymentSuccessSignalR(
      String orderId, double amount) {
    if (!mounted) return;
    // Không cancel polling timer ở đây — cần tiếp tục poll để bắt status updates
    // _pollingTimer?.cancel();

    ref.read(chatHistoryProvider.notifier).update((state) {
      return state.map((m) {
        if (m['orderId']?.toString().toLowerCase() == orderId.toLowerCase()) {
          return {
            ...m,
            'isPaidBill': true,
            'amount': amount > 0 ? amount : (m['amount'] ?? 0.0),
            'qrCode': null,
            'text':
                'Cảm ơn bạn! Dạ em đã nhận được thanh toán. Mã QR lấy hàng tại quán đã sẵn sàng bên dưới nhé!',
          };
        }
        return m;
      }).toList();
    });

    _showTopNotification(
      'Thanh toán thành công ${amount > 0 ? "${amount.toInt()}đ" : ""}!',
      AppColors.success,
      Icons.check_circle_outline,
    );
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
          autoAddToCart: true,
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
    ref.listen<List<MockOrder>>(orderProvider, (previous, next) {
      if (previous == null || previous.isEmpty) return;
      for (final newOrder in next) {
        final oldOrder = previous.firstWhere(
          (o) => o.id == newOrder.id,
          orElse: () => newOrder,
        );
        if (oldOrder.id == newOrder.id && oldOrder.status != newOrder.status) {
          String statusMsgText = '';
          String rawStatusStr = '';
          switch (newOrder.status) {
            case MockOrderStatus.pendingConfirm:
              statusMsgText = '⏳ Quán đã nhận thông tin đơn và đang kiểm tra.';
              rawStatusStr = 'PendingConfirmation';
              break;
            case MockOrderStatus.preparing:
              statusMsgText = '👨‍🍳 Bếp đang chế biến món ăn của bạn.';
              rawStatusStr = 'Preparing';
              break;
            case MockOrderStatus.ready:
              statusMsgText = '🔔 Món ăn đã chuẩn bị xong! Mời bạn đến nhận món tại quầy.';
              rawStatusStr = 'ReadyForPickup';
              break;
            case MockOrderStatus.completed:
              statusMsgText = '🎉 Đơn hàng đã hoàn thành. Cảm ơn bạn!';
              rawStatusStr = 'Completed';
              break;
            case MockOrderStatus.cancelled:
              statusMsgText = '❌ Đơn hàng đã được hủy.';
              rawStatusStr = 'Cancelled';
              break;
          }

          if (statusMsgText.isNotEmpty) {
            _showTopNotification(
                statusMsgText, AppColors.primary, Icons.info_outline);
            ref.read(chatHistoryProvider.notifier).update((chatState) {
              final exists = chatState.any((m) =>
                  m['orderId'] == newOrder.id &&
                  m['orderStatus'] == rawStatusStr);
              if (exists) return chatState;

              final newMsg = {
                'isUser': false,
                'messageType': 'ORDER_TRACKING',
                'orderId': newOrder.id,
                'orderStatus': rawStatusStr,
                'text': statusMsgText,
                'time':
                    '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                'updatedAt': DateTime.now(),
              };
              return [...chatState, newMsg];
            });
            _scrollToBottom();
          }
        }
      }
    });

    final currentUser = ref.watch(currentUserProvider);
    final rawMessages = ref.watch(chatHistoryProvider);
    final orders = ref.watch(orderProvider);

    final messages = List<Map<String, dynamic>>.from(rawMessages);

    // 🛡️ Collect all paid bill slots and sort paid bills strictly by real orderTime (Date + Time) descending:
    // Newest bill (mới đặt e.g. 20/08 15:48) is placed FIRST (top slot), older bill (đặt trước e.g. 18/08 20:56) is placed AFTER (lower slot)!
    final List<int> paidIndices = [];
    final List<Map<String, dynamic>> paidBills = [];

    for (int i = 0; i < messages.length; i++) {
      if (messages[i]['isPaidBill'] == true) {
        paidIndices.add(i);
        paidBills.add(Map<String, dynamic>.from(messages[i]));
      }
    }

    paidBills.sort((a, b) {
      DateTime timeA = parseChatMsgTime(a['updatedAt'] ?? a['createdAt'] ?? a['time']);
      DateTime timeB = parseChatMsgTime(b['updatedAt'] ?? b['createdAt'] ?? b['time']);

      final idA = a['orderId']?.toString();
      if (idA != null && idA.isNotEmpty) {
        final oA = orders.firstWhere(
          (o) => o.id.toLowerCase() == idA.toLowerCase(),
          orElse: () => MockOrder(id: '', storeName: '', items: [], totalAmount: 0, status: MockOrderStatus.pendingConfirm, orderTime: DateTime.now(), pickupTime: DateTime.now(), originalMinutes: 15, timeline: []),
        );
        if (oA.id.isNotEmpty) timeA = oA.orderTime;
      }

      final idB = b['orderId']?.toString();
      if (idB != null && idB.isNotEmpty) {
        final oB = orders.firstWhere(
          (o) => o.id.toLowerCase() == idB.toLowerCase(),
          orElse: () => MockOrder(id: '', storeName: '', items: [], totalAmount: 0, status: MockOrderStatus.pendingConfirm, orderTime: DateTime.now(), pickupTime: DateTime.now(), originalMinutes: 15, timeline: []),
        );
        if (oB.id.isNotEmpty) timeB = oB.orderTime;
      }

      return timeA.compareTo(timeB); // Older Date+Time FIRST (Top), newly placed bill AFTER (Bottom)
    });

    for (int k = 0; k < paidIndices.length; k++) {
      messages[paidIndices[k]] = paidBills[k];
    }

    final startIndex = (messages.length - _displayedMessagesCount).clamp(0, messages.length);
    final visibleMessages = messages.sublist(startIndex);
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
            icon: Icon(
              _showGuidanceCard ? Icons.help : Icons.help_outline_rounded,
              color: Colors.white,
            ),
            tooltip: 'Hướng dẫn sử dụng AI',
            onPressed: () {
              setState(() {
                _showGuidanceCard = !_showGuidanceCard;
              });
            },
          ),
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
          // Message list or AI Guidance Welcome View
          Expanded(
            child: (messages.isEmpty || _showGuidanceCard)
                ? AiWelcomeGuidanceCard(
                    onActionTap: (query) {
                      setState(() {
                        _showGuidanceCard = false;
                      });
                      _textController.text = query;
                      _sendMessage(query);
                    },
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 20),
                    physics: const BouncingScrollPhysics(),
                    itemCount:
                        visibleMessages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == visibleMessages.length && _isTyping) {
                        return _buildTypingRow();
                      }

                      final msg = visibleMessages[index];
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
                  key: ValueKey(msg['id'] ?? msg['orderId'] ?? '${msg['time']}_$index'),
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
                            if (!isUser && msg['isPaidBill'] == true)
                              PaidBillTicketCard(
                                orderId: msg['orderId']?.toString() ?? '',
                                amount: (msg['amount'] as num?)?.toDouble() ?? 0.0,
                                storeName: msg['storeName']?.toString() ?? msg['orderPreview']?['store_name']?.toString(),
                                items: msg['items'] as List<dynamic>? ?? msg['resolvedItems'] as List<dynamic>?,
                                orderStatus: msg['orderStatus']?.toString(),
                                updatedAt: () {
                                   final msgOrderId = msg['orderId']?.toString();
                                   if (msgOrderId != null && msgOrderId.isNotEmpty) {
                                     final realOrder = orders.firstWhere(
                                       (o) => o.id.toLowerCase() == msgOrderId.toLowerCase(),
                                       orElse: () => MockOrder(id: '', storeName: '', items: [], totalAmount: 0, status: MockOrderStatus.pendingConfirm, orderTime: DateTime.now(), pickupTime: DateTime.now(), originalMinutes: 15, timeline: []),
                                     );
                                     if (realOrder.id.isNotEmpty) return realOrder.orderTime;
                                   }
                                   return parseChatMsgTime(msg['updatedAt']);
                                 }(),
                                onViewDetails: () {
                                  final orderId = msg['orderId']?.toString() ?? '';
                                  if (orderId.isNotEmpty) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => OrderDetailPage(orderId: orderId),
                                      ),
                                    );
                                  }
                                },
                              )
                            else if (!isUser && (msg['messageType'] == 'ORDER_TRACKING' || msg['orderStatus'] != null))
                              OrderStatusNoticeCard(
                                orderId: msg['orderId']?.toString() ?? '',
                                status: msg['orderStatus']?.toString() ?? msg['status']?.toString() ?? 'PendingConfirmation',
                                updatedAt: parseChatMsgTime(msg['updatedAt']),
                                qrCode: msg['qrCode']?.toString(),
                                amount: (msg['amount'] as num?)?.toDouble(),
                                onViewDetails: () {
                                  final orderId = msg['orderId']?.toString() ?? '';
                                  if (orderId.isNotEmpty) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => OrderDetailPage(orderId: orderId),
                                      ),
                                    );
                                  }
                                },
                              )
                            else
                              ChatBubble(
                                text: text,
                                isUser: isUser,
                                onSuggestionTap: (selectedQuery) {
                                  _textController.text = selectedQuery;
                                  _sendMessage(selectedQuery);
                                },
                              ),
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


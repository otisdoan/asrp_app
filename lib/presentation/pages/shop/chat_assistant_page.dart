import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/cart_provider.dart';
import '../../../data/models/cart_item_model.dart';
import '../../../data/models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/network/dio_client.dart';
import '../../../providers/branch_provider.dart';
import 'store_detail_page.dart';

final chatHistoryProvider = StateProvider<List<Map<String, dynamic>>>((ref) {
  return [
    {
      'isUser': false,
      'text': 'Xin chào! Tôi là trợ lý ảo AI DineX. Tôi có thể giúp gì cho bạn hôm nay? (Bạn có thể chọn câu hỏi gợi ý bên dưới hoặc tự nhập câu hỏi nhé)',
      'time': '18:32',
      'showChips': true,
    }
  ];
});

class ChatAssistantPage extends ConsumerStatefulWidget {
  const ChatAssistantPage({super.key});

  @override
  ConsumerState<ChatAssistantPage> createState() => _ChatAssistantPageState();
}

class _ChatAssistantPageState extends ConsumerState<ChatAssistantPage> {
  late final String _sessionId = 'session_default_user';

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  OverlayEntry? _activeOverlayEntry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChatHistory();
    });
  }

  Future<void> _loadChatHistory() async {
    try {
      final response = await DioClient().dio.get('/ai/chat/history', queryParameters: {'sessionId': _sessionId});
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
        content: const Text('Bạn có chắc chắn muốn xóa toàn bộ lịch sử trò chuyện này không?'),
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
                await DioClient().dio.delete('/ai/chat/history', queryParameters: {'sessionId': _sessionId});
              } catch (_) {}
              final now = DateTime.now();
              final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
              ref.read(chatHistoryProvider.notifier).state = [
                {
                  'isUser': false,
                  'text': 'Xin chào! Tôi là trợ lý ảo AI DineX. Tôi có thể giúp gì cho bạn hôm nay?',
                  'time': timeStr,
                  'showChips': true,
                }
              ];
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

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

  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;
    _textController.clear();

    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

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

    // 2. Get branch list and resolve active branch ID
    final branchesAsync = ref.read(branchesFutureProvider);
    String branchId = '00000000-0000-0000-0000-000000000000'; // Default GUID
    branchesAsync.whenData((list) {
      if (list.isNotEmpty) {
        branchId = list.first.id;
      }
    });

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
      final response = await DioClient().dio.post(
        '/ai/chat',
        data: {
          'branchId': branchId,
          'sessionId': _sessionId,
          'message': text,
          'chatHistory': history,
        },
      );

      if (!mounted) return;

      final data = response.data;
      final replyTime = DateTime.now();
      final replyTimeStr = '${replyTime.hour.toString().padLeft(2, '0')}:${replyTime.minute.toString().padLeft(2, '0')}';

      // Log API response for debugging
      print('================ [Flutter AI Chat] RESPONSE LOG ================');
      print('User Message: $text');
      print('AI Reply: ${data['reply']}');
      print('Recommendations (keywords): ${data['recommendations']}');
      print('BranchRecommendations (cards): ${data['branchRecommendations']}');
      print('===============================================================');

      ref.read(chatHistoryProvider.notifier).update((state) => [
        ...state,
        {
          'isUser': false,
          'text': data['reply'] as String? ?? 'Xin lỗi, hệ thống đang gặp sự cố.',
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
          'text': 'Không thể kết nối đến máy chủ AI. Vui lòng kiểm tra lại kết nối mạng.',
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
    final currentUser = ref.watch(currentUserProvider);
    final messages = ref.watch(chatHistoryProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDFB), // Ultra-clean light orange-tinted background
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
                final text = msg['text'] as String;
                final time = msg['time'] as String? ?? '';
                final showChips = msg['showChips'] as bool? ?? false;
                final recommendations = msg['recommendations'] as List<dynamic>?;
                final branchRecommendations = msg['branchRecommendations'] as List<dynamic>?;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    mainAxisAlignment:
                        isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
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
                            _buildChatBubble(text, isUser),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                time,
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: AppColors.textTertiary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (branchRecommendations != null && branchRecommendations.isNotEmpty) ...[
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
                colors: [AppColors.primary, AppColors.secondary], // Elegant orange brand gradient
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isUser ? null : const Color(0xFFFFFDFB), // Soft warm peach background for AI
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(isUser ? 20 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 20),
        ),
        border: isUser
            ? null
            : Border.all(color: const Color(0xFFFFE5DA), width: 1.0), // Warm orange border
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
                          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                      border: Border.all(color: const Color(0xFFFFEDD5), width: 1.0),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: (rec['imageUrl'] != null && (rec['imageUrl'] as String).isNotEmpty)
                          ? Image.network(
                              rec['imageUrl'] as String,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
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
                                  colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
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
                          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
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
                              'Xem chi tiết',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 8,
                              color: Color(0xFF4B5563),
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
                            color: const Color(0xFFEA580C).withValues(alpha: 0.15),
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
                                fontSize: 12,
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

// lib/presentation/pages/shop/chat_agent_page.dart

import 'package:flutter/material.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';

class ChatAgentPage extends StatefulWidget {
  final String orderId;
  
  const ChatAgentPage({super.key, required this.orderId});

  @override
  State<ChatAgentPage> createState() => _ChatAgentPageState();
}

class _ChatAgentPageState extends State<ChatAgentPage> with WidgetsBindingObserver {
  HubConnection? _hubConnection;
  final List<Map<String, dynamic>> _messages = [];
  String? _selectedPickupTime;
  List<String> _availablePickupTimes = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _generateAvailablePickupTimes();
    _initSignalR();
    _messages.add({
      'messageType': 'TEXT',
      'data': {'text': 'Chào bạn, đơn hàng của bạn đã được lên nháp. Bạn có muốn thanh toán ngay không?'}
    });
  }

  void _generateAvailablePickupTimes() {
    final now = DateTime.now();
    _availablePickupTimes = List.generate(6, (index) {
      final slotTime = now.add(Duration(minutes: 15 + index * 15));
      return slotTime.toIso8601String();
    });
    if (_availablePickupTimes.isNotEmpty) {
      _selectedPickupTime = _availablePickupTimes.first;
    }
  }

  Future<void> _initSignalR() async {
    _hubConnection = HubConnectionBuilder()
        .withUrl(ApiConstants.chatAgentHubUrl)
        .withAutomaticReconnect()
        .build();

    _hubConnection?.onreconnecting(({error}) {
      debugPrint("[SignalR Agent] Reconnecting: $error");
    });

    _hubConnection?.onreconnected(({connectionId}) {
      debugPrint("[SignalR Agent] Reconnected ($connectionId). Re-joining order tracking...");
      _hubConnection?.invoke("JoinOrderTracking", args: [widget.orderId]);
    });

    _hubConnection?.on("ReceiveAgentMessage", _handleIncomingMessage);

    try {
      await _hubConnection?.start();
      await _hubConnection?.invoke("JoinOrderTracking", args: [widget.orderId]);
    } catch (e) {
      debugPrint("SignalR Connection Error: $e");
    }
  }

  void _handleIncomingMessage(List<Object?>? args) {
    if (!mounted) return;
    if (args != null && args.isNotEmpty && args[0] is Map) {
      final payload = Map<String, dynamic>.from(args[0] as Map);
      setState(() {
        if (payload['messageType'] == 'ORDER_TRACKING') {
          _messages.removeWhere((m) => m['messageType'] == 'ORDER_TRACKING');
        }
        if (payload['messageType'] == 'PAYMENT_SUCCESS') {
          _messages.removeWhere((m) => m['messageType'] == 'PAYMENT_QR');
        }
        _messages.add(payload);
      });
    }
  }

  Future<void> _generatePaymentQr() async {
    try {
      final response = await DioClient().dio.post(
        '/ai/chat/payment-qr',
        data: {
          'orderId': widget.orderId,
          'pickupTime': _selectedPickupTime,
        },
      );

      if (!mounted) return;
      if (response.data != null && response.data is Map) {
        final data = Map<String, dynamic>.from(response.data as Map);
        setState(() {
          _messages.add(data);
        });
      }
    } catch (e) {
      debugPrint("Generate QR Error: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    try {
      _hubConnection?.stop();
    } catch (e) {
      debugPrint("Error stopping SignalR: $e");
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _reconnectAndSyncData();
    }
  }

  Future<void> _reconnectAndSyncData() async {
    if (_hubConnection != null && _hubConnection!.state == HubConnectionState.Disconnected) {
      debugPrint("Đang kết nối lại SignalR...");
      try {
        await _hubConnection!.start();
        await _hubConnection!.invoke("JoinOrderTracking", args: [widget.orderId]);
      } catch (e) {
        debugPrint("SignalR Reconnect Error: $e");
      }
    }
    await _fetchLatestOrderStatus();
  }

  Future<void> _fetchLatestOrderStatus() async {
    try {
      final response = await DioClient().dio.get(
        '/orders/${widget.orderId}/status',
        options: Options(headers: {
          'X-Internal-Api-Key': 'dinex-rag-internal-key-8f9a2b'
        }),
      );
      if (!mounted) return;
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        setState(() {
          _messages.removeWhere((m) => m['messageType'] == 'ORDER_TRACKING');
          _messages.add({
            'messageType': 'ORDER_TRACKING',
            'data': {
              'orderId': data['orderId'],
              'status': data['orderStatus'],
              'paymentStatus': data['paymentStatus']
            }
          });
        });
      }
    } catch (e) {
      debugPrint("Sync Order Status Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trợ lý ảo AI DineX'), backgroundColor: Colors.deepOrange),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildDynamicWidget(_messages[index]);
              },
            ),
          ),
          _buildActionArea(),
        ],
      ),
    );
  }

  Widget _buildDynamicWidget(Map<String, dynamic> message) {
    final type = message['messageType'];
    final data = message['data'] ?? {};

    switch (type) {
      case 'TEXT':
        return _buildTextBubble(data['text']);
      case 'PAYMENT_QR':
        return _buildQrPaymentCard(data);
      case 'PAYMENT_SUCCESS':
        return _buildPaymentSuccessCard(data);
      case 'ORDER_TRACKING':
        return _buildOrderTrackingTimeline(data);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTextBubble(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text),
      ),
    );
  }

  Widget _buildQrPaymentCard(Map<String, dynamic> data) {
    final qrCode = data['qrCode'] as String?;
    final amount = data['amount'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text("Quét mã để thanh toán", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            if (qrCode != null && qrCode.isNotEmpty)
              QrImageView(
                data: qrCode,
                version: QrVersions.auto,
                size: 200.0,
              )
            else
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Mã QR không khả dụng", style: TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 12),
            if (amount != null)
              Text("Số tiền: $amount đ", style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSuccessCard(Map<String, dynamic> data) {
    return Card(
      color: Colors.green[50],
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.green)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Thanh toán thành công!", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text("Đã nhận ${data['amount'] ?? ''} đ. Bếp đang chuẩn bị món.", style: TextStyle(color: Colors.green[800], fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickupTimeSelector() {
    if (_availablePickupTimes.isEmpty) return const SizedBox.shrink();

    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Chọn giờ nhận món',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      initialValue: _selectedPickupTime ?? _availablePickupTimes.first,
      items: _availablePickupTimes.map((time) {
        final localTime = DateTime.parse(time).toLocal();
        final displayTime = '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';
        return DropdownMenuItem(value: time, child: Text(displayTime));
      }).toList(),
      onChanged: (val) => setState(() => _selectedPickupTime = val),
    );
  }

  Widget _buildOrderTrackingTimeline(Map<String, dynamic> data) {
    final status = data['status']?.toString() ?? '';
    
    int currentStep = 0;
    bool isError = false;

    switch (status) {
      case 'PendingConfirmation':
      case '0':
        currentStep = 0;
        break;
      case 'Preparing':
      case '1':
      case '2':
        currentStep = 1;
        break;
      case 'ReadyForPickup':
      case '3':
        currentStep = 2;
        break;
      case 'Completed':
      case '4':
        currentStep = 3;
        break;
      case 'Cancelled': 
      case '5':
        currentStep = 0; 
        isError = true; 
        break;
      case 'PendingInventory':
        currentStep = 0;
        break;
      default:
        currentStep = 0;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Tiến trình đơn hàng", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            if (isError)
              const Text("Đơn hàng đã bị hủy. Vui lòng liên hệ hỗ trợ.", style: TextStyle(color: Colors.red))
            else if (status == 'PendingInventory')
              const Text("Quán đang kiểm tra lại nguyên liệu, vui lòng chờ trong giây lát...", style: TextStyle(color: Colors.orange))
            else
              Stepper(
                physics: const ClampingScrollPhysics(),
                currentStep: currentStep,
                controlsBuilder: (context, details) => const SizedBox.shrink(),
                steps: [
                  Step(
                    title: const Text('Chờ xác nhận'),
                    content: const SizedBox.shrink(),
                    isActive: currentStep >= 0,
                    state: currentStep > 0 ? StepState.complete : StepState.indexed,
                  ),
                  Step(
                    title: const Text('Đang làm món'),
                    content: const Text('Bếp đang chuẩn bị món ăn cho bạn.'),
                    isActive: currentStep >= 1,
                    state: currentStep > 1 ? StepState.complete : StepState.indexed,
                  ),
                  Step(
                    title: const Text('Sẵn sàng giao/nhận'),
                    content: const Text('Món ăn đã xong, bạn có thể nhận món.'),
                    isActive: currentStep >= 2,
                    state: currentStep > 2 ? StepState.complete : StepState.indexed,
                  ),
                  Step(
                    title: const Text('Hoàn thành'),
                    content: const SizedBox.shrink(),
                    isActive: currentStep >= 3,
                    state: currentStep == 3 ? StepState.complete : StepState.indexed,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionArea() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPickupTimeSelector(),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
              ),
              onPressed: _generatePaymentQr,
              icon: const Icon(Icons.qr_code),
              label: const Text("Xác nhận & Khởi tạo mã QR"),
            ),
          ],
        ),
      ),
    );
  }
}

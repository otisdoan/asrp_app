import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';

typedef OnMessageReceived = void Function(List<Object?>? args);
typedef OnReconnectedCallback = void Function(String? connectionId);

class SignalRService {
  HubConnection? _hubConnection;
  bool _isConnecting = false;

  HubConnectionState get state => _hubConnection?.state ?? HubConnectionState.Disconnected;

  void initConnection({
    required String serverUrl,
    String? accessToken,
    OnMessageReceived? onMessageReceived,
    OnReconnectedCallback? onReconnected,
  }) {
    final httpOptions = HttpConnectionOptions(
      accessTokenFactory: accessToken != null ? () async => accessToken : null,
    );

    _hubConnection = HubConnectionBuilder()
        .withUrl(serverUrl, options: httpOptions)
        .withAutomaticReconnect()
        .build();

    if (onMessageReceived != null) {
      _hubConnection?.on("ReceiveAgentMessage", onMessageReceived);
    }

    _hubConnection?.onclose(({error}) {
      debugPrint("[SignalRService] Connection closed: $error");
    });

    _hubConnection?.onreconnecting(({error}) {
      debugPrint("[SignalRService] Reconnecting... Error: $error");
    });

    _hubConnection?.onreconnected(({connectionId}) {
      debugPrint("[SignalRService] Reconnected successfully. ConnectionId: $connectionId");
      if (onReconnected != null) {
        onReconnected(connectionId);
      }
    });
  }

  Future<void> startConnection() async {
    if (_hubConnection == null) return;
    if (_hubConnection!.state == HubConnectionState.Connected || _isConnecting) return;

    try {
      _isConnecting = true;
      await _hubConnection!.start();
      debugPrint("[SignalRService] SignalR Connected successfully.");
    } catch (e) {
      debugPrint("[SignalRService] Connection start error: $e");
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> joinOrderTracking(String orderId) async {
    if (_hubConnection != null && _hubConnection!.state == HubConnectionState.Connected) {
      try {
        await _hubConnection!.invoke("JoinOrderTracking", args: [orderId]);
        debugPrint("[SignalRService] Joined Order Tracking group for order: $orderId");
      } catch (e) {
        debugPrint("[SignalRService] Error joining order tracking: $e");
      }
    }
  }

  Future<void> stopConnection() async {
    if (_hubConnection != null) {
      try {
        await _hubConnection!.stop();
        debugPrint("[SignalRService] SignalR Connection stopped.");
      } catch (e) {
        debugPrint("[SignalRService] Error stopping connection: $e");
      }
    }
  }
}

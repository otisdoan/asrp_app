import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../../firebase_options.dart';
import '../network/dio_client.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}

  if (kDebugMode) {
    print('[FCM Background Message]: ${message.messageId} - ${message.notification?.title}');
  }

  final notification = message.notification;
  final title = notification?.title ?? message.data['title'] ?? 'DineX Thông báo';
  final body = notification?.body ?? message.data['body'] ?? message.data['message'] ?? '';

  if (title.isNotEmpty || body.isNotEmpty) {
    final localNotifications = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    const androidChannel = AndroidNotificationChannel(
      'dinex_high_importance_channel',
      'DineX Important Notifications',
      description: 'Used for order updates, stock alerts, and transfer ticket notifications.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    await localNotifications.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          androidChannel.id,
          androidChannel.name,
          channelDescription: androidChannel.description,
          icon: '@mipmap/ic_launcher',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }
}

class AppNotificationService {
  AppNotificationService._();
  static final AppNotificationService instance = AppNotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final DioClient _dioClient = DioClient();

  bool _isInitialized = false;
  GoRouter? _router;

  void setRouter(GoRouter router) {
    _router = router;
  }

  void handleNotificationNavigation(Map<String, dynamic> data) {
    if (_router == null) return;

    final link = data['link'] as String?;
    final orderId = data['orderId'] as String?;
    final type = data['type'] as String?;

    if (orderId != null && orderId.isNotEmpty) {
      _router!.go('/payment-success?orderId=$orderId');
      return;
    }

    if (link != null && link.isNotEmpty) {
      if (link.startsWith('/orders/')) {
        final extractedOrderId = link.replaceAll('/orders/', '');
        if (extractedOrderId.isNotEmpty) {
          _router!.go('/payment-success?orderId=$extractedOrderId');
          return;
        }
      }
      
      try {
        _router!.go(link);
        return;
      } catch (e) {
        if (kDebugMode) {
          print('[NotificationService] Direct navigation error for $link: $e');
        }
      }
    }

    if (type == 'order_created' || type == 'kitchen_order') {
      try {
        _router!.go('/cashier');
      } catch (_) {}
    }
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    // 1. Setup Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. Initialize Local Notifications for Foreground & Background Banners
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        if (kDebugMode) {
          print('[Notification Clicked]: ${details.payload}');
        }
        if (details.payload != null && details.payload!.isNotEmpty) {
          try {
            final data = jsonDecode(details.payload!) as Map<String, dynamic>;
            handleNotificationNavigation(data);
          } catch (_) {}
        }
      },
    );

    // 3. Create Android High Importance Channel
    const androidChannel = AndroidNotificationChannel(
      'dinex_high_importance_channel',
      'DineX Important Notifications',
      description: 'Used for order updates, stock alerts, and transfer ticket notifications.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // 4. Request Permissions
    await requestPermission();

    // 5. Listen to Foreground FCM Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('[FCM Foreground Message]: ${message.notification?.title} - ${message.notification?.body}');
      }
      final notification = message.notification;
      final title = notification?.title ?? message.data['title'] ?? 'DineX Thông báo';
      final body = notification?.body ?? message.data['body'] ?? message.data['message'] ?? '';

      if (title.isNotEmpty || body.isNotEmpty) {
        _localNotifications.show(
          message.hashCode,
          title,
          body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              androidChannel.id,
              androidChannel.name,
              channelDescription: androidChannel.description,
              icon: '@mipmap/ic_launcher',
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
              enableVibration: true,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: jsonEncode(message.data),
        );
      }
    });

    // 6. Listen to App Opened via Notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('[FCM App Opened from Notification]: ${message.data}');
      }
      handleNotificationNavigation(message.data);
    });

    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      if (kDebugMode) {
        print('[FCM App Launched from Terminated Notification]: ${initialMessage.data}');
      }
      handleNotificationNavigation(initialMessage.data);
    }

    _isInitialized = true;
  }

  Future<void> requestPermission() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
    }

    if (kDebugMode) {
      print('[FCM Permission Status]: ${settings.authorizationStatus}');
    }
  }

  Future<void> registerDeviceToken() async {
    try {
      final token = await _fcm.getToken();
      if (token == null || token.isEmpty) return;

      if (kDebugMode) {
        print('[FCM Register Token]: $token');
      }

      await _dioClient.dio.post(
        '/notifications/device-tokens',
        data: {
          'token': token,
          'platform': Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'web'),
          'deviceId': token.substring(0, token.length > 32 ? 32 : token.length),
          'appVersion': '1.0.0',
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('[NotificationService] Register device token error: $e');
      }
    }
  }

  Future<void> unregisterDeviceToken() async {
    try {
      final token = await _fcm.getToken();
      if (token == null || token.isEmpty) return;

      await _dioClient.dio.delete(
        '/notifications/device-tokens',
        data: {
          'token': token,
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('[NotificationService] Unregister device token error: $e');
      }
    }
  }
}

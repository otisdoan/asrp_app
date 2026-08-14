import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'firebase_options.dart';
import 'core/services/notification_service.dart';
import 'app/app.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize Firebase
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('[Firebase] ✅ Initialized');
    }
  } catch (e) {
    print('[Firebase] ⚠️ Initialization warning: $e');
  }

  // Initialize App Notification Service & Request Permissions
  try {
    await AppNotificationService.instance.initialize();
  } catch (e) {
    print('[NotificationService] ⚠️ Initialization error: $e');
  }

  // Lock to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Remove native splash screen
  FlutterNativeSplash.remove();

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}

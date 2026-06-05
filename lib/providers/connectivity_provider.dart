import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityProvider = StateNotifierProvider<ConnectivityNotifier, bool>((ref) {
  return ConnectivityNotifier();
});

class ConnectivityNotifier extends StateNotifier<bool> {
  Timer? _timer;
  bool _isChecking = false;

  ConnectivityNotifier() : super(true) {
    _startChecking();
  }

  void _startChecking() {
    // Check immediately on startup
    checkAndUpdate();
    // Check periodically every 5 seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      checkAndUpdate();
    });
  }

  Future<bool> checkAndUpdate() async {
    if (_isChecking) return state;
    _isChecking = true;
    
    final isOnline = await _hasInternet();
    
    _isChecking = false;
    if (state != isOnline) {
      state = isOnline;
    }
    return isOnline;
  }

  Future<bool> _hasInternet() async {
    try {
      // Lookup google.com to verify actual internet access
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void setOffline() {
    if (state) {
      state = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

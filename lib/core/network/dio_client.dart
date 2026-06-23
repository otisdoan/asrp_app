import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;
  DioClient._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  String? _accessToken;

  late final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  )..interceptors.addAll([
    _AuthInterceptor(
      getToken: () => _accessToken,
      onRefresh: _handleRefresh,
      onLogout: _handleLogout,
    ),
  ]);

  Dio get dio => _dio;

  void setAccessToken(String? token) {
    _accessToken = token;
  }

  String? get accessToken => _accessToken;

  Future<void> clearAuth() async {
    _accessToken = null;
    await _secureStorage.delete(key: AppConstants.storageKeyAccessToken);
    await _secureStorage.delete(key: AppConstants.storageKeyRefreshToken);
  }

  Future<String?> _handleRefresh() async {
    try {
      final refreshToken = await _secureStorage.read(key: AppConstants.storageKeyRefreshToken);
      if (refreshToken == null) {
        await clearAuth();
        return null;
      }

      final response = await Dio(BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $refreshToken',
        },
      )).post(
        ApiConstants.refresh,
        data: {
          'refreshToken': refreshToken,
        },
      );

      // Support dynamic api envelope structures (either wrapped in data or directly returned)
      final data = response.data['data'] ?? response.data;
      final newToken = data['accessToken'] as String;
      
      _accessToken = newToken;
      await _secureStorage.write(
        key: AppConstants.storageKeyAccessToken,
        value: newToken,
      );

      // Save new refresh token if backend implements token rotation
      final newRefreshToken = data['refreshToken'] as String?;
      if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
        await _secureStorage.write(
          key: AppConstants.storageKeyRefreshToken,
          value: newRefreshToken,
        );
      }

      return newToken;
    } catch (_) {
      await clearAuth();
      return null;
    }
  }

  Future<void> _handleLogout() async {
    await clearAuth();
    // Navigation handled by app-level auth state
  }
}

class _AuthInterceptor extends Interceptor {
  final String? Function() getToken;
  final Future<String?> Function() onRefresh;
  final Future<void> Function() onLogout;
  bool _isRefreshing = false;
  final List<RequestOptions> _retryQueue = [];

  _AuthInterceptor({
    required this.getToken,
    required this.onRefresh,
    required this.onLogout,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _handleRequest(options, handler);
  }

  Future<void> _handleRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    var token = getToken();
    if (token != null) {
      if (_isTokenExpired(token)) {
        if (!_isRefreshing) {
          _isRefreshing = true;
          token = await onRefresh();
          _isRefreshing = false;
        } else {
          while (_isRefreshing) {
            await Future.delayed(const Duration(milliseconds: 100));
          }
          token = getToken();
        }
      }

      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload = parts[1];
      var normalized = payload;
      switch (normalized.length % 4) {
        case 2:
          normalized += '==';
          break;
        case 3:
          normalized += '=';
          break;
      }

      final String decoded = utf8.decode(base64Url.decode(normalized));
      final Map<String, dynamic> claims = jsonDecode(decoded);

      if (claims.containsKey('exp')) {
        final exp = claims['exp'] as int;
        final expiryTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        // Refresh if token has less than 30 seconds of lifetime left
        return DateTime.now().isAfter(expiryTime.subtract(const Duration(seconds: 30)));
      }
      return true;
    } catch (_) {
      return true;
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    final url = err.requestOptions.path;
    if (url.contains('/auth/login') || url.contains('/auth/refresh')) {
      handler.next(err);
      return;
    }

    if (_isRefreshing) {
      _retryQueue.add(err.requestOptions);
      handler.next(err);
      return;
    }

    _isRefreshing = true;
    final newToken = await onRefresh();
    _isRefreshing = false;

    if (newToken == null) {
      await onLogout();
      handler.next(err);
      return;
    }

    // Retry original request
    try {
      final dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
      err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
      final response = await dio.fetch(err.requestOptions);
      handler.resolve(response);
    } catch (e) {
      handler.next(err);
    }
  }
}

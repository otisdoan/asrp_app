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
  }

  Future<String?> _handleRefresh() async {
    try {
      final response = await Dio(BaseOptions(baseUrl: ApiConstants.baseUrl))
          .post(ApiConstants.refresh);
      final newToken = response.data['data']['accessToken'] as String;
      _accessToken = newToken;
      await _secureStorage.write(
        key: AppConstants.storageKeyAccessToken,
        value: newToken,
      );
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
    final token = getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
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

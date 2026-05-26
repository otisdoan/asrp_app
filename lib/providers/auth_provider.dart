import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../data/models/user_model.dart';
import '../data/models/auth_response_model.dart';
import '../data/repositories/auth_repository.dart';
import '../core/network/dio_client.dart';
import '../core/constants/app_constants.dart';

// ===== Auth State =====
class AuthState {
  final UserModel? user;
  final String? accessToken;
  final bool isAuthenticated;

  const AuthState({
    this.user,
    this.accessToken,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    UserModel? user,
    String? accessToken,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      accessToken: accessToken ?? this.accessToken,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

// ===== Auth Notifier =====
class AuthNotifier extends StateNotifier<AuthState> {
  final _secureStorage = const FlutterSecureStorage();
  final AuthRepository _authRepository = AuthRepository();

  AuthNotifier() : super(const AuthState()) {
    _loadSavedSession();
  }

  /// Tự động nạp lại phiên đăng nhập cũ từ Secure Storage khi khởi động app
  Future<void> _loadSavedSession() async {
    try {
      final token =
          await _secureStorage.read(key: AppConstants.storageKeyAccessToken);
      final userJson =
          await _secureStorage.read(key: AppConstants.storageKeyUser);
      if (token != null && userJson != null) {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        final user = UserModel.fromJson(userMap);
        // Removed audit avatar log

        DioClient().setAccessToken(token);

        state = AuthState(
          user: user,
          accessToken: token,
          isAuthenticated: true,
        );
      }
    } catch (_) {
      logout();
    }
  }

  /// Thiết lập thông tin xác thực sau khi đăng nhập/đăng ký thành công
  Future<void> setCredentials(AuthResponseModel response) async {
    DioClient().setAccessToken(response.accessToken);
    await _secureStorage.write(
      key: AppConstants.storageKeyAccessToken,
      value: response.accessToken,
    );
    await _secureStorage.write(
      key: AppConstants.storageKeyRefreshToken,
      value: response.refreshToken,
    );
    await _secureStorage.write(
      key: AppConstants.storageKeyUser,
      value: jsonEncode(response.user.toJson()),
    );
    // Removed audit avatar log

    state = AuthState(
      user: response.user,
      accessToken: response.accessToken,
      isAuthenticated: true,
    );
    // Removed audit avatar log
  }

  /// Cập nhật thông tin chi tiết của user hiện tại
  Future<void> setUser(UserModel user) async {
    await _secureStorage.write(
      key: AppConstants.storageKeyUser,
      value: jsonEncode(user.toJson()),
    );
    state = state.copyWith(user: user);
    // Removed audit avatar log
  }

  /// Cập nhật Access Token mới (ví dụ khi được Refresh thành công)
  Future<void> updateAccessToken(String token) async {
    DioClient().setAccessToken(token);
    await _secureStorage.write(
      key: AppConstants.storageKeyAccessToken,
      value: token,
    );
    state = state.copyWith(accessToken: token);
  }

  /// Đăng xuất - Xóa sạch mọi phiên lưu trữ và credentials
  Future<void> logout() async {
    final refreshToken =
        await _secureStorage.read(key: AppConstants.storageKeyRefreshToken);

    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _authRepository.logout(refreshToken);
      }
    } catch (_) {
      // Mat mang hoac backend loi: van tiep tuc xoa local session.
    } finally {
      await DioClient().clearAuth();
      await _secureStorage.delete(key: AppConstants.storageKeyAccessToken);
      await _secureStorage.delete(key: AppConstants.storageKeyRefreshToken);
      await _secureStorage.delete(key: AppConstants.storageKeyUser);
      state = const AuthState();
    }
  }
}

// ===== Providers =====
final authRepositoryProvider =
    Provider<AuthRepository>((ref) => AuthRepository());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);

// Derived providers
final isAuthenticatedProvider = Provider<bool>(
  (ref) => ref.watch(authProvider).isAuthenticated,
);

final currentUserProvider = Provider<UserModel?>(
  (ref) => ref.watch(authProvider).user,
);

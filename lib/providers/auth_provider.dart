import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../data/models/user_model.dart';
import '../data/models/auth_response_model.dart';
import '../data/repositories/auth_repository.dart';
import '../core/network/dio_client.dart';
import '../core/constants/app_constants.dart';
import '../core/services/notification_service.dart';
import 'branch_provider.dart';

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

        DioClient().setAccessToken(token);

        state = AuthState(
          user: user,
          accessToken: token,
          isAuthenticated: true,
        );

        // Tải thông tin mới nhất từ Server (bao gồm Xu DX và Cấp Hạng)
        refreshProfile();

        // Đăng ký FCM Device Token cho thiết bị
        AppNotificationService.instance.registerDeviceToken();
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

    state = AuthState(
      user: response.user,
      accessToken: response.accessToken,
      isAuthenticated: true,
    );

    // Đăng ký FCM Device Token cho thiết bị
    AppNotificationService.instance.registerDeviceToken();
  }

  /// Cập nhật thông tin chi tiết của user hiện tại
  Future<void> setUser(UserModel user) async {
    await _secureStorage.write(
      key: AppConstants.storageKeyUser,
      value: jsonEncode(user.toJson()),
    );
    state = state.copyWith(user: user);
  }

  /// Tải lại hồ sơ mới nhất từ backend API và cập nhật state
  Future<void> refreshProfile() async {
    try {
      final repo = AuthRepository();
      final freshUser = await repo.fetchProfile();
      if (freshUser != null) {
        final current = state.user;
        final mergedUser = UserModel(
          id: freshUser.id.isNotEmpty ? freshUser.id : (current?.id ?? ''),
          username: freshUser.username.isNotEmpty ? freshUser.username : (current?.username ?? ''),
          email: freshUser.email ?? current?.email,
          phone: freshUser.phone ?? current?.phone,
          fullName: freshUser.fullName ?? current?.fullName,
          avatar: freshUser.avatar ?? current?.avatar,
          gender: freshUser.gender ?? current?.gender,
          birthday: freshUser.birthday ?? current?.birthday,
          brandId: freshUser.brandId ?? current?.brandId,
          branchId: freshUser.branchId ?? current?.branchId,
          role: (current?.role != null && current!.role.isNotEmpty) ? current.role : freshUser.role,
          isActive: freshUser.isActive,
          points: freshUser.points,
          tier: freshUser.tier,
          address: freshUser.address ?? current?.address,
          createdAt: freshUser.createdAt.isNotEmpty ? freshUser.createdAt : (current?.createdAt ?? ''),
          updatedAt: freshUser.updatedAt.isNotEmpty ? freshUser.updatedAt : (current?.updatedAt ?? ''),
        );
        await setUser(mergedUser);
      }
    } catch (e) {
      print('[AuthNotifier] refreshProfile error: $e');
    }
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
    try {
      await AppNotificationService.instance.unregisterDeviceToken();
      final refreshToken =
          await _secureStorage.read(key: AppConstants.storageKeyRefreshToken);
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await AuthRepository().logout(refreshToken);
      }
    } catch (e) {
      print('[AuthNotifier] logout backend call error: $e');
    }
    await DioClient().clearAuth();
    await _secureStorage.delete(key: AppConstants.storageKeyAccessToken);
    await _secureStorage.delete(key: AppConstants.storageKeyRefreshToken);
    await _secureStorage.delete(key: AppConstants.storageKeyUser);
    state = const AuthState();
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

/// Checks if current logged in user is a staff/manager/owner of the specified target branch.
bool isBranchStaffOrOwner(dynamic ref, String? targetBranchId, {String? storeBrandId}) {
  if (targetBranchId == null || targetBranchId.isEmpty) return false;

  final UserModel? user = ref.read(currentUserProvider);
  if (user == null) return false;

  final role = user.role.toLowerCase();
  if (role == 'customer') return false;

  // 1. If user is directly assigned to a specific branchId (e.g. Staff or Branch Manager)
  if (user.branchId != null && user.branchId!.isNotEmpty) {
    return user.branchId == targetBranchId;
  }

  // 2. If user is a Merchant Owner / Brand Manager (has brandId)
  if (user.brandId != null && user.brandId!.isNotEmpty) {
    if (storeBrandId != null && storeBrandId.isNotEmpty && storeBrandId == user.brandId) {
      return true;
    }
    try {
      final brandBranches = ref.read(myBrandBranchesFutureProvider).valueOrNull;
      if (brandBranches != null && brandBranches.isNotEmpty) {
        return brandBranches.any((b) => b.id == targetBranchId);
      }
    } catch (_) {}
  }

  return false;
}

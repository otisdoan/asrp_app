import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_model.dart';
import '../data/models/auth_response_model.dart';

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
  AuthNotifier() : super(const AuthState());

  void setCredentials(AuthResponseModel response) {
    state = AuthState(
      user: response.user,
      accessToken: response.accessToken,
      isAuthenticated: true,
    );
  }

  void setUser(UserModel user) {
    state = state.copyWith(user: user);
  }

  void updateAccessToken(String token) {
    state = state.copyWith(accessToken: token);
  }

  void logout() {
    state = const AuthState();
  }
}

// ===== Provider =====
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/auth_provider.dart';

/// Login Page — professional, clean design.
/// Two tabs: Khách hàng (phone + password) and Nhân viên (phone + password).
/// Follows RULE: UI-only widgets, AppColors 100%, responsive.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  // Shared controllers
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordVisible = false;
  bool _loading = false;
  String? _phoneError;
  String? _passwordError;
  String? _loginError;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validate() {
    setState(() {
      _phoneError = null;
      _passwordError = null;
    });
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || !RegExp(r'^0[0-9]{8,9}$').hasMatch(phone)) {
      setState(() => _phoneError = 'Số điện thoại không hợp lệ');
    }
    if (_passwordController.text.length < 8) {
      setState(() => _passwordError = 'Mật khẩu tối thiểu 8 ký tự');
    }
  }

  Future<void> _login() async {
    if (_loading) return;
    _validate();
    if (_phoneError != null || _passwordError != null) return;
    setState(() {
      _loading = true;
      _loginError = null;
    });

    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    try {
      final repository = ref.read(authRepositoryProvider);
      final response = await repository.login(
        phone: phone,
        password: password,
      );

      // Save credentials and JWT
      await ref.read(authProvider.notifier).setCredentials(response);

      if (!mounted) return;
      const storage = FlutterSecureStorage();
      await storage.write(key: 'user_role', value: response.user.role);

      if (mounted) {
        if (response.user.role == 'customer') {
          final hasOnboarded = await storage.read(key: 'onboarding_completed');
          if (!mounted) return;
          if (hasOnboarded == 'true') {
            context.go(AppConstants.routeHome);
          } else {
            context.go(AppConstants.routeOnboarding);
          }
        } else if (response.user.role == 'staff') {
          context.go(AppConstants.routeStaffHome);
        } else {
          context.go(AppConstants.routeCashier);
        }
      }
    } catch (e) {
      if (e is DioException) {
        print('[Backend Login Error] Status: ${e.response?.statusCode}');
        print('[Backend Login Error] Data: ${e.response?.data}');
      } else {
        print('[Login Error]: $e');
      }
      setState(() {
        _loading = false;
        _loginError = e is DioException
            ? (e.response?.data['message'] ?? 'Đăng nhập thất bại từ máy chủ')
            : e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              // Logo / Brand
              Center(child: _buildBrandHeader()),
              const SizedBox(height: 36),
              // Form fields
              _buildPhoneField(),
              const SizedBox(height: 16),
              _buildPasswordField(),
              const SizedBox(height: 8),
              // Forgot password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push(AppConstants.routeForgotPassword),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  child: const Text(
                    'Quên mật khẩu?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              if (_loginError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _loginError!,
                  style: const TextStyle(fontSize: 13, color: AppColors.error),
                ),
              ],
              const SizedBox(height: 20),
              // Login button
              _buildLoginButton(),
              const SizedBox(height: 24),
              // Register link
              _buildRegisterLink(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Brand Header ──────────────────────────────────────────────────────
  Widget _buildBrandHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.restaurant_menu, color: AppColors.onPrimary, size: 28),
        ),
        const SizedBox(height: 12),
        const Text(
          'BMC Phở Express',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Chào mừng trở lại!',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        const Text(
          'Đăng nhập để tiếp tục đặt món yêu thích',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ─── Phone Field ───────────────────────────────────────────────────────
  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Số điện thoại',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: '0901234567',
            hintStyle: const TextStyle(color: AppColors.textPlaceholder),
            prefixIcon: const Icon(Icons.phone_outlined, size: 20, color: AppColors.textTertiary),
            filled: true,
            fillColor: AppColors.surfaceContainerLowest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorText: _phoneError,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  // ─── Password Field ────────────────────────────────────────────────────
  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mật khẩu',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: !_passwordVisible,
          style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Nhập mật khẩu',
            hintStyle: const TextStyle(color: AppColors.textPlaceholder),
            prefixIcon: const Icon(Icons.lock_outline, size: 20, color: AppColors.textTertiary),
            suffixIcon: IconButton(
              icon: Icon(
                _passwordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: AppColors.textTertiary,
              ),
              onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
            ),
            filled: true,
            fillColor: AppColors.surfaceContainerLowest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorText: _passwordError,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  // ─── Login Button ──────────────────────────────────────────────────────
  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: _loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: AppColors.onPrimary,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Đăng nhập',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }

  // ─── Register Link ─────────────────────────────────────────────────────
  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Chưa có tài khoản? ',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        GestureDetector(
          onTap: () => context.push(AppConstants.routeRegister),
          child: const Text(
            'Đăng ký ngay',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

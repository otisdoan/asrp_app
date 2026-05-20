import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';

/// Register Page — professional, clean design.
/// Two tabs: Khách hàng (phone + password + confirm → OTP) and Nhân viên (phone + password + confirm → done).
/// Follows RULE: UI-only widgets, AppColors 100%, responsive.
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});
  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _passwordVisible = false;
  bool _confirmVisible = false;
  bool _loading = false;
  String? _phoneError;
  String? _passwordError;
  String? _confirmError;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validate() {
    setState(() {
      _phoneError = null;
      _passwordError = null;
      _confirmError = null;
    });
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || !RegExp(r'^0[0-9]{8,9}$').hasMatch(phone)) {
      setState(() => _phoneError = 'Số điện thoại không hợp lệ');
    }
    final pw = _passwordController.text;
    if (pw.length < 8) {
      setState(() => _passwordError = 'Mật khẩu tối thiểu 8 ký tự');
    } else if (!RegExp(r'[a-zA-Z]').hasMatch(pw)) {
      setState(() => _passwordError = 'Mật khẩu phải bao gồm chữ cái');
    } else if (!RegExp(r'[0-9]').hasMatch(pw)) {
      setState(() => _passwordError = 'Mật khẩu phải bao gồm số');
    }
    if (_confirmPasswordController.text != pw) {
      setState(() => _confirmError = 'Mật khẩu xác nhận không khớp');
    }
  }

  Future<void> _register() async {
    _validate();
    if (_phoneError != null || _passwordError != null || _confirmError != null) return;
    setState(() => _loading = true);

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // Go to OTP verification
    setState(() => _loading = false);
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => OtpVerificationPage(
          phone: _phoneController.text.trim(),
        ),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
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
              const SizedBox(height: 16),
              // Back button
              _buildBackButton(),
              const SizedBox(height: 24),
              // Header
              Center(child: _buildHeader()),
              const SizedBox(height: 24),
              // Form
              _buildPhoneField(),
              const SizedBox(height: 16),
              _buildPasswordField(),
              const SizedBox(height: 16),
              _buildConfirmPasswordField(),
              const SizedBox(height: 28),
              // Register button
              _buildRegisterButton(),
              const SizedBox(height: 24),
              // Login link
              _buildLoginLink(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Back Button ───────────────────────────────────────────────────────
  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => context.pop(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.bgSoft,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.arrow_back, size: 20, color: AppColors.textPrimary),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────
  Widget _buildHeader() {
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
          'Tạo tài khoản',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        const Text(
          'Đăng ký để đặt món và nhận ưu đãi',
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
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
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
          decoration: _inputDecoration(
            hint: '0901234567',
            prefixIcon: Icons.phone_outlined,
            errorText: _phoneError,
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
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: !_passwordVisible,
          style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
          decoration: _inputDecoration(
            hint: 'Ít nhất 8 ký tự, có chữ và số',
            prefixIcon: Icons.lock_outline,
            errorText: _passwordError,
            suffixIcon: IconButton(
              icon: Icon(
                _passwordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: AppColors.textTertiary,
              ),
              onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Confirm Password Field ────────────────────────────────────────────
  Widget _buildConfirmPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Xác nhận mật khẩu',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: !_confirmVisible,
          style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
          decoration: _inputDecoration(
            hint: 'Nhập lại mật khẩu',
            prefixIcon: Icons.lock_outline,
            errorText: _confirmError,
            suffixIcon: IconButton(
              icon: Icon(
                _confirmVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: AppColors.textTertiary,
              ),
              onPressed: () => setState(() => _confirmVisible = !_confirmVisible),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Register Button ───────────────────────────────────────────────────
  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : _register,
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
                child: CircularProgressIndicator(color: AppColors.onPrimary, strokeWidth: 2),
              )
            : const Text(
                'Đăng ký',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }

  // ─── Login Link ────────────────────────────────────────────────────────
  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Đã có tài khoản? ',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        GestureDetector(
          onTap: () => context.pop(),
          child: const Text(
            'Đăng nhập',
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

  // ─── Input Decoration Helper ───────────────────────────────────────────
  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
    String? errorText,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textPlaceholder),
      prefixIcon: Icon(prefixIcon, size: 20, color: AppColors.textTertiary),
      suffixIcon: suffixIcon,
      errorText: errorText,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// OTP Verification Page — shown only for customer registration.
// ═══════════════════════════════════════════════════════════════════════════

class OtpVerificationPage extends StatefulWidget {
  final String phone;
  const OtpVerificationPage({super.key, required this.phone});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _loading = false;
  String? _error;
  int _resendCooldown = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startCooldown() {
    setState(() {
      _resendCooldown = 60;
      _canResend = false;
    });
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendCooldown--);
      if (_resendCooldown <= 0) {
        setState(() => _canResend = true);
        return false;
      }
      return true;
    });
  }

  String get _otpValue => _otpControllers.map((c) => c.text).join();

  Future<void> _verifyOtp() async {
    if (_otpValue.length < 6) {
      setState(() => _error = 'Vui lòng nhập đủ 6 số OTP');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    // Mock: accept any 6-digit OTP
    if (_otpValue == '123456' || _otpValue.length == 6) {
      // Success → go to home
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        GoRouter.of(context).go(AppConstants.routeHome);
      }
    } else {
      setState(() {
        _loading = false;
        _error = 'Mã OTP không đúng';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Back button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.bgSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back, size: 20, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(height: 32),
              // Header
              const Text(
                'Xác thực OTP',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Mã xác thực đã được gửi đến\n${widget.phone}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 36),
              // OTP Input
              _buildOtpInput(),
              // Error
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(fontSize: 13, color: AppColors.error),
                ),
              ],
              const SizedBox(height: 24),
              // Resend
              _buildResendRow(),
              const SizedBox(height: 32),
              // Verify button
              _buildVerifyButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── OTP Input ─────────────────────────────────────────────────────────
  Widget _buildOtpInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 48,
          height: 56,
          child: TextFormField(
            controller: _otpControllers[index],
            focusNode: _focusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: AppColors.surfaceContainerLowest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onChanged: (value) {
              if (value.isNotEmpty && index < 5) {
                _focusNodes[index + 1].requestFocus();
              } else if (value.isEmpty && index > 0) {
                _focusNodes[index - 1].requestFocus();
              }
              // Auto verify when all filled
              if (_otpValue.length == 6) {
                _verifyOtp();
              }
            },
          ),
        );
      }),
    );
  }

  // ─── Resend Row ────────────────────────────────────────────────────────
  Widget _buildResendRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Không nhận được mã? ',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        GestureDetector(
          onTap: _canResend ? _startCooldown : null,
          child: Text(
            _canResend ? 'Gửi lại' : 'Gửi lại (${_resendCooldown}s)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _canResend ? AppColors.primary : AppColors.textTertiary,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Verify Button ─────────────────────────────────────────────────────
  Widget _buildVerifyButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : _verifyOtp,
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
                child: CircularProgressIndicator(color: AppColors.onPrimary, strokeWidth: 2),
              )
            : const Text(
                'Xác nhận',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}

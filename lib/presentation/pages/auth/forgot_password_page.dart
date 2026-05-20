import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

/// Forgot Password Page — enter phone → OTP verification → reset password.
/// Follows RULE: UI-only widgets, AppColors 100%, responsive.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _phoneController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendResetCode() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || !RegExp(r'^0[0-9]{8,9}$').hasMatch(phone)) {
      setState(() => _error = 'Số điện thoại không hợp lệ');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _loading = false);

    // Navigate to OTP page
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => _ForgotPasswordOtpPage(phone: phone),
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
              GestureDetector(
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
              ),
              const SizedBox(height: 32),
              // Brand logo
              Center(
                child: Column(
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
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'Quên mật khẩu?',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Nhập số điện thoại đã đăng ký để nhận\nmã khôi phục mật khẩu.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 28),
              // Phone field
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(fontSize: 13, color: AppColors.error)),
              ],
              const SizedBox(height: 28),
              // Send button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _sendResetCode,
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
                          'Gửi mã khôi phục',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Forgot Password OTP Page — verify OTP then go to Reset Password.
// ═══════════════════════════════════════════════════════════════════════════

class _ForgotPasswordOtpPage extends StatefulWidget {
  final String phone;
  const _ForgotPasswordOtpPage({required this.phone});

  @override
  State<_ForgotPasswordOtpPage> createState() => _ForgotPasswordOtpPageState();
}

class _ForgotPasswordOtpPageState extends State<_ForgotPasswordOtpPage> {
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
    if (_otpValue.length == 6) {
      // Success → go to reset password page
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const _ResetPasswordFromOtpPage(),
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
        child: SingleChildScrollView(
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
              const Center(
                child: Text(
                  'Xác thực OTP',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Mã xác thực đã được gửi đến\n${widget.phone}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 36),
              // OTP Input
              _buildOtpInput(),
              // Error
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(fontSize: 13, color: AppColors.error)),
              ],
              const SizedBox(height: 24),
              // Resend
              _buildResendRow(),
              const SizedBox(height: 32),
              // Verify button
              SizedBox(
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
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

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
              if (_otpValue.length == 6) {
                _verifyOtp();
              }
            },
          ),
        );
      }),
    );
  }

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
}

// ═══════════════════════════════════════════════════════════════════════════
// Reset Password (after OTP verified) — new password + confirm.
// ═══════════════════════════════════════════════════════════════════════════

class _ResetPasswordFromOtpPage extends StatefulWidget {
  const _ResetPasswordFromOtpPage();

  @override
  State<_ResetPasswordFromOtpPage> createState() => _ResetPasswordFromOtpPageState();
}

class _ResetPasswordFromOtpPageState extends State<_ResetPasswordFromOtpPage> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _passwordVisible = false;
  bool _confirmVisible = false;
  bool _loading = false;
  bool _success = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final pw = _passwordController.text;
    if (pw.length < 8) {
      setState(() => _error = 'Mật khẩu tối thiểu 8 ký tự');
      return;
    }
    if (!RegExp(r'[a-zA-Z]').hasMatch(pw)) {
      setState(() => _error = 'Mật khẩu phải bao gồm chữ cái');
      return;
    }
    if (!RegExp(r'[0-9]').hasMatch(pw)) {
      setState(() => _error = 'Mật khẩu phải bao gồm số');
      return;
    }
    if (_confirmController.text != pw) {
      setState(() => _error = 'Mật khẩu xác nhận không khớp');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() {
        _loading = false;
        _success = true;
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
              if (!_success) ...[
                _buildResetForm(),
              ] else ...[
                _buildSuccessState(),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResetForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            'Đặt lại mật khẩu',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'Tạo mật khẩu mới cho tài khoản của bạn.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: 28),
        // New password
        const Text(
          'Mật khẩu mới',
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
        const SizedBox(height: 16),
        // Confirm password
        const Text(
          'Xác nhận mật khẩu mới',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _confirmController,
          obscureText: !_confirmVisible,
          style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
          decoration: _inputDecoration(
            hint: 'Nhập lại mật khẩu mới',
            prefixIcon: Icons.lock_outline,
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
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(fontSize: 13, color: AppColors.error)),
        ],
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _resetPassword,
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
                    'Đặt lại mật khẩu',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            color: AppColors.successContainer,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle, size: 44, color: AppColors.success),
        ),
        const SizedBox(height: 24),
        const Text(
          'Đặt lại thành công!',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Mật khẩu đã được cập nhật.\nBạn có thể đăng nhập với mật khẩu mới.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              // Pop all the way back to login
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text(
              'Đăng nhập ngay',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textPlaceholder),
      prefixIcon: Icon(prefixIcon, size: 20, color: AppColors.textTertiary),
      suffixIcon: suffixIcon,
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

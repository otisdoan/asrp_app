import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _identifierController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  bool _isValidIdentifier(String value) {
    final phoneRegex = RegExp(r'^0[0-9]{8,9}$');
    final emailRegex =
        RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
    return phoneRegex.hasMatch(value) || emailRegex.hasMatch(value);
  }

  String _normalizeIdentifier(String value) {
    if (value.contains('@')) {
      return value;
    }
    if (value.startsWith('0')) {
      return '+84${value.substring(1)}';
    }
    return value;
  }

  Future<void> _sendResetCode() async {
    final rawInput = _identifierController.text.trim();
    if (rawInput.isEmpty || !_isValidIdentifier(rawInput)) {
      setState(() => _error = 'Vui lòng nhập số điện thoại hoặc email hợp lệ');
      return;
    }

    final identifier = _normalizeIdentifier(rawInput);

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .forgotPassword(phoneOrEmail: identifier);
      if (!mounted) return;
      setState(() => _loading = false);

      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) =>
              _ForgotPasswordOtpPage(phoneOrEmail: identifier),
          transitionsBuilder: (_, animation, __, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      final serverMessage = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['message']?.toString() ??
              e.response?.data['error']?.toString())
          : null;
      setState(() {
        _loading = false;
        _error = serverMessage ??
            (e.response?.statusCode == 400
                ? 'Thông tin khôi phục không hợp lệ'
                : 'Gửi mã khôi phục thất bại');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Gửi mã khôi phục thất bại: $e';
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
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.bgSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back,
                      size: 20, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(height: 32),
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
                      padding: const EdgeInsets.all(8),
                      child:
                          Image.asset('assets/logo.png', fit: BoxFit.contain),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'DineX',
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
                  'Nhập số điện thoại hoặc email đã đăng ký để nhận mã khôi phục mật khẩu.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Số điện thoại hoặc email',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _identifierController,
                keyboardType: TextInputType.emailAddress,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(100),
                ],
                style:
                    const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: '0901234567 hoặc email@domain.com',
                  hintStyle: const TextStyle(color: AppColors.textPlaceholder),
                  prefixIcon: const Icon(Icons.alternate_email,
                      size: 20, color: AppColors.textTertiary),
                  filled: true,
                  fillColor: AppColors.surfaceContainerLowest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style:
                        const TextStyle(fontSize: 13, color: AppColors.error)),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _sendResetCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: AppColors.onPrimary, strokeWidth: 2),
                        )
                      : const Text(
                          'Gửi mã khôi phục',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
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

class _ForgotPasswordOtpPage extends ConsumerStatefulWidget {
  const _ForgotPasswordOtpPage({required this.phoneOrEmail});

  final String phoneOrEmail;

  @override
  ConsumerState<_ForgotPasswordOtpPage> createState() =>
      _ForgotPasswordOtpPageState();
}

class _ForgotPasswordOtpPageState
    extends ConsumerState<_ForgotPasswordOtpPage> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _loading = false;
  String? _error;
  int _resendCooldown = AppConstants.otpCooldownSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String get _otpValue =>
      _otpControllers.map((controller) => controller.text).join();

  void _startCooldown() {
    _timer?.cancel();
    setState(() {
      _resendCooldown = AppConstants.otpCooldownSeconds;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCooldown <= 1) {
        timer.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  Future<void> _verifyOtp() async {
    if (_otpValue.length < AppConstants.otpLength) {
      setState(() => _error = 'Vui lòng nhập đủ 6 số OTP');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(authRepositoryProvider).verifyOtpForReset(
            phoneOrEmail: widget.phoneOrEmail,
            otp: _otpValue,
          );

      if (!mounted) return;
      setState(() => _loading = false);

      context.go(
        Uri(
          path: AppConstants.routeResetPassword,
          queryParameters: {
            'phone': widget.phoneOrEmail,
            'otp': _otpValue,
          },
        ).toString(),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      final serverMessage = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['message']?.toString() ??
              e.response?.data['error']?.toString())
          : null;
      setState(() {
        _loading = false;
        _error = serverMessage ??
            (e.response?.statusCode == 400
                ? 'Mã OTP không hợp lệ'
                : 'Xác thực OTP thất bại');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Xác thực OTP thất bại: $e';
      });
    }
  }

  Future<void> _resendOtp() async {
    if (_loading || _resendCooldown > 0) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(authRepositoryProvider).forgotPassword(
            phoneOrEmail: widget.phoneOrEmail,
          );

      if (!mounted) return;
      setState(() => _loading = false);
      _startCooldown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mã OTP mới đã được gửi')),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      final serverMessage = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['message']?.toString() ??
              e.response?.data['error']?.toString())
          : null;
      setState(() {
        _loading = false;
        _error = serverMessage ??
            (e.response?.statusCode == 400
                ? 'Không thể gửi lại mã OTP'
                : 'Lỗi gửi lại OTP');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Lỗi gửi lại OTP: $e';
      });
    }
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
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onChanged: (value) {
              if (value.isNotEmpty && index < 5) {
                _focusNodes[index + 1].requestFocus();
              } else if (value.isEmpty && index > 0) {
                _focusNodes[index - 1].requestFocus();
              }
              if (_otpValue.length == AppConstants.otpLength && !_loading) {
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
          onTap: _resendCooldown > 0 ? null : _resendOtp,
          child: Text(
            _resendCooldown > 0 ? 'Gửi lại ($_resendCooldown s)' : 'Gửi lại',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _resendCooldown > 0
                  ? AppColors.textTertiary
                  : AppColors.primary,
            ),
          ),
        ),
      ],
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
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.bgSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back,
                      size: 20, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(height: 32),
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
                  'Mã xác thực đã được gửi đến\n${widget.phoneOrEmail}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 36),
              _buildOtpInput(),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style:
                        const TextStyle(fontSize: 13, color: AppColors.error)),
              ],
              const SizedBox(height: 24),
              _buildResendRow(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: AppColors.onPrimary, strokeWidth: 2),
                        )
                      : const Text(
                          'Xác nhận',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
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

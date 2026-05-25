import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../providers/auth_provider.dart';

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
  bool _confirmPasswordVisible = false;
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
    if (_passwordController.text.length < 8) {
      setState(() => _passwordError = 'Mật khẩu tối thiểu 8 ký tự');
    }
    if (_confirmPasswordController.text != _passwordController.text) {
      setState(() => _confirmError = 'Mật khẩu xác nhận không khớp');
    }
  }

  String _formatPhone(String phone) {
    if (phone.startsWith('0')) {
      return '+84${phone.substring(1)}';
    }
    return phone;
  }

  bool _isFirebaseAvailable() {
    try {
      FirebaseAuth.instance.app;
      return true;
    } catch (_) {
      return false;
    }
  }

  InputDecoration _inputDecoration(
      {required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: AppColors.bgSoft,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Future<void> _storeUserAndRoute(UserModel userProfile) async {
    await ref.read(authProvider.notifier).setUser(userProfile);
    const storage = FlutterSecureStorage();
    await storage.write(key: 'user_role', value: userProfile.role);

    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);

    if (userProfile.role == 'customer') {
      final hasOnboarded = await storage.read(key: 'onboarding_completed');
      if (!mounted) return;
      if (hasOnboarded == 'true') {
        context.go(AppConstants.routeHome);
      } else {
        context.go(AppConstants.routeOnboarding);
      }
    } else if (userProfile.role == 'staff') {
      context.go(AppConstants.routeStaffHome);
    } else if (userProfile.role == 'admin' || userProfile.role == 'manager') {
      context.go(AppConstants.routeCashier);
    } else {
      context.go(AppConstants.routeCashier);
    }
  }

  void _openOtpPage(String verificationId, String phone) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OtpVerificationPage(
          verificationId: verificationId,
          phone: phone,
          password: _passwordController.text,
        ),
      ),
    );
  }

  Future<void> _register() async {
    if (_loading) return;
    _validate();
    if (_phoneError != null ||
        _passwordError != null ||
        _confirmError != null) {
      return;
    }

    setState(() => _loading = true);
    final formattedPhone = _formatPhone(_phoneController.text.trim());

    if (!_isFirebaseAvailable() || formattedPhone == '+84000000000') {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() => _loading = false);
      _openOtpPage('mock_verification_id', formattedPhone);
      return;
    }

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            final authResult =
                await FirebaseAuth.instance.signInWithCredential(credential);
            final user = authResult.user;
            if (user == null) {
              throw Exception('Không thể đăng nhập Firebase');
            }

            final idToken = await user.getIdToken();
            if (idToken == null) {
              throw Exception('Không lấy được ID Token từ Firebase');
            }

            final repository = ref.read(authRepositoryProvider);
            final response = await repository.register(
              idToken: idToken,
              password: _passwordController.text,
            );
            await ref.read(authProvider.notifier).setCredentials(response);

            print(
                '[Audit Profile Sync] Register(auto): đã setCredentials xong, chuẩn bị gọi getProfile()');
            try {
              final userProfile =
                  await ref.read(userRepositoryProvider).getProfile();
              print(
                  '[Audit Profile Sync] Register(auto): userProfile.avatar = ${userProfile.avatar}');
              await _storeUserAndRoute(userProfile);
              print(
                  '[Audit Profile Sync] Register(auto): đã setUser(userProfile) thành công');
            } catch (profileError) {
              print(
                  '[Audit Profile Sync] Register(auto): lỗi khi gọi getProfile/setUser = $profileError');
              rethrow;
            }
          } catch (e) {
            if (!mounted) return;
            setState(() {
              _loading = false;
              _phoneError = 'Đăng ký tự động thất bại: $e';
            });
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;
          setState(() {
            _loading = false;
            _phoneError = e.message ?? 'Xác thực số điện thoại thất bại';
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!mounted) return;
          setState(() => _loading = false);
          _openOtpPage(verificationId, formattedPhone);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _phoneError = 'Lỗi gửi mã OTP: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
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
              const SizedBox(height: 28),
              const Text(
                'Tạo tài khoản',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Đăng ký bằng số điện thoại để bắt đầu sử dụng ứng dụng.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration(
                        label: 'Số điện thoại', icon: Icons.phone_outlined)
                    .copyWith(errorText: _phoneError),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: !_passwordVisible,
                decoration: _inputDecoration(
                        label: 'Mật khẩu', icon: Icons.lock_outline)
                    .copyWith(
                  errorText: _passwordError,
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _passwordVisible = !_passwordVisible),
                    icon: Icon(
                      _passwordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                obscureText: !_confirmPasswordVisible,
                decoration: _inputDecoration(
                        label: 'Xác nhận mật khẩu',
                        icon: Icons.lock_reset_outlined)
                    .copyWith(
                  errorText: _confirmError,
                  suffixIcon: IconButton(
                    onPressed: () => setState(() =>
                        _confirmPasswordVisible = !_confirmPasswordVisible),
                    icon: Icon(
                      _confirmPasswordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Đăng ký',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Đã có tài khoản? ',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Text(
                      'Đăng nhập',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OtpVerificationPage extends ConsumerStatefulWidget {
  const OtpVerificationPage({
    super.key,
    required this.verificationId,
    required this.phone,
    required this.password,
  });

  final String verificationId;
  final String phone;
  final String password;

  @override
  ConsumerState<OtpVerificationPage> createState() =>
      _OtpVerificationPageState();
}

class _OtpVerificationPageState extends ConsumerState<OtpVerificationPage> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _loading = false;
  String? _error;
  int _resendCooldown = 0;
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

  bool _isFirebaseAvailable() {
    try {
      FirebaseAuth.instance.app;
      return true;
    } catch (_) {
      return false;
    }
  }

  String _formatPhone(String phone) {
    if (phone.startsWith('0')) {
      return '+84${phone.substring(1)}';
    }
    return phone;
  }

  String get _otpValue =>
      _otpControllers.map((controller) => controller.text).join();

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _resendCooldown = 60);
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

  Future<void> _syncProfileAndRoute(UserModel userProfile) async {
    await ref.read(authProvider.notifier).setUser(userProfile);
    const storage = FlutterSecureStorage();
    await storage.write(key: 'user_role', value: userProfile.role);

    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);

    if (userProfile.role == 'customer') {
      final hasOnboarded = await storage.read(key: 'onboarding_completed');
      if (!mounted) return;
      if (hasOnboarded == 'true') {
        context.go(AppConstants.routeHome);
      } else {
        context.go(AppConstants.routeOnboarding);
      }
    } else if (userProfile.role == 'staff') {
      context.go(AppConstants.routeStaffHome);
    } else if (userProfile.role == 'admin' || userProfile.role == 'manager') {
      context.go(AppConstants.routeCashier);
    } else {
      context.go(AppConstants.routeCashier);
    }
  }

  Future<void> _verifyOtp() async {
    if (_loading) return;
    if (_otpValue.length < 6) {
      setState(() => _error = 'Vui lòng nhập đủ 6 số OTP');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      String idToken = 'mock_firebase_id_token';

      if (widget.verificationId != 'mock_verification_id') {
        final credential = PhoneAuthProvider.credential(
          verificationId: widget.verificationId,
          smsCode: _otpValue,
        );
        final authResult =
            await FirebaseAuth.instance.signInWithCredential(credential);
        final firebaseUser = authResult.user;
        if (firebaseUser == null) {
          throw Exception('Không thể đăng nhập Firebase');
        }
        final token = await firebaseUser.getIdToken();
        if (token == null) {
          throw Exception('Không lấy được ID Token từ Firebase');
        }
        idToken = token;
      } else {
        await Future.delayed(const Duration(milliseconds: 800));
        if (_otpValue != '123456') {
          throw Exception('Mã OTP không đúng (Chế độ thử nghiệm: 123456)');
        }
      }

      final repository = ref.read(authRepositoryProvider);
      final response = await repository.register(
        idToken: idToken,
        password: widget.password,
      );
      await ref.read(authProvider.notifier).setCredentials(response);

      print(
          '[Audit Profile Sync] Register(OTP): đã setCredentials xong, chuẩn bị gọi getProfile()');
      try {
        final userProfile = await ref.read(userRepositoryProvider).getProfile();
        print(
            '[Audit Profile Sync] Register(OTP): userProfile.avatar = ${userProfile.avatar}');
        await _syncProfileAndRoute(userProfile);
        print(
            '[Audit Profile Sync] Register(OTP): đã setUser(userProfile) thành công');
      } catch (profileError) {
        print(
            '[Audit Profile Sync] Register(OTP): lỗi khi gọi getProfile/setUser = $profileError');
        rethrow;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is DioException
            ? (e.response?.data['message'] ?? 'Đăng ký thất bại từ máy chủ')
            : e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _resendOtp() async {
    if (_loading || _resendCooldown > 0) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final formattedPhone = _formatPhone(widget.phone);

    if (widget.verificationId == 'mock_verification_id' ||
        !_isFirebaseAvailable()) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() => _loading = false);
      _startCooldown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mã OTP mới đã được gửi')),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) {},
        verificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;
          setState(() {
            _loading = false;
            _error = e.message ?? 'Gửi lại OTP thất bại';
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!mounted) return;
          setState(() => _loading = false);
          _startCooldown();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mã OTP mới đã được gửi')),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Lỗi gửi lại OTP: $e';
      });
    }
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 46,
      height: 56,
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: AppColors.bgSoft,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          }
          if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: 28),
              const Text(
                'Xác thực OTP',
                style: TextStyle(
                  fontSize: 28,
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
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, _buildOtpBox),
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(
                  _error!,
                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Xác nhận OTP',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: _resendCooldown > 0 ? null : _resendOtp,
                  child: Text(
                    _resendCooldown > 0
                        ? 'Gửi lại sau $_resendCooldown giây'
                        : 'Gửi lại mã OTP',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

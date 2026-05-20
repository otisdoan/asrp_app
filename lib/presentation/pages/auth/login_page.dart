import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Customer flow
  int _customerStep = 1;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  int _otpCooldown = 0;
  int _otpExpiry = AppConstants.otpExpirySeconds;
  Timer? _cooldownTimer;
  Timer? _expiryTimer;
  bool _customerLoading = false;
  String? _customerError;

  // Staff flow
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _staffPasswordVisible = false;
  bool _staffLoading = false;
  String? _staffError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _cooldownTimer?.cancel();
    _expiryTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _otpCooldown = AppConstants.otpCooldownSeconds);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        if (_otpCooldown > 0) _otpCooldown--;
        else t.cancel();
      });
    });
  }

  void _startExpiry() {
    setState(() => _otpExpiry = AppConstants.otpExpirySeconds);
    _expiryTimer?.cancel();
    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        if (_otpExpiry > 0) _otpExpiry--;
        else t.cancel();
      });
    });
  }

  String _formatCountdown(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m}:${sec.toString().padLeft(2,'0')}';
  }

  Future<void> _sendOtp() async {
    if (_nameController.text.trim().length < 2) {
      setState(() => _customerError = 'Ten phai co it nhat 2 ky tu');
      return;
    }
    final phone = _phoneController.text.trim();
    if (!RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
      setState(() => _customerError = 'So dien thoai phai co dung 10 chu so');
      return;
    }
    setState(() { _customerLoading = true; _customerError = null; });
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() { _customerLoading = false; _customerStep = 2; });
    _startCooldown();
    _startExpiry();
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.length != 6) {
      setState(() => _customerError = 'Vui long nhap du 6 so OTP');
      return;
    }
    if (_otpController.text != AppConstants.mockOtp) {
      setState(() => _customerError = 'Ma OTP khong dung');
      return;
    }
    setState(() { _customerLoading = true; _customerError = null; });
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) context.go(AppConstants.routeHome);
  }

  Future<void> _staffLogin() async {
    if (_usernameController.text.trim().length < 3) {
      setState(() => _staffError = 'Ten dang nhap toi thieu 3 ky tu');
      return;
    }
    if (_passwordController.text.length < 8) {
      setState(() => _staffError = 'Mat khau toi thieu 8 ky tu');
      return;
    }
    setState(() { _staffLoading = true; _staffError = null; });
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) context.go(AppConstants.routeHome);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 48),
                // Logo
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: const Center(child: Text('🍜', style: TextStyle(fontSize: 32))),
                ),
                const SizedBox(height: 16),
                Text('BMC Phở Express', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary)),
                const SizedBox(height: 4),
                Text('Nền tảng nhà hàng thông minh', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 32),
                // Tab bar
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    dividerColor: Colors.transparent,
                    tabs: const [Tab(text: 'Khách hàng'), Tab(text: 'Nhân viên')],
                    onTap: (_) => setState(() { _customerError = null; _staffError = null; }),
                  ),
                ),
                const SizedBox(height: 24),
                // Tab content
                SizedBox(
                  height: 420,
                  child: TabBarView(
                    controller: _tabController,
                    children: [_buildCustomerTab(), _buildStaffTab()],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerTab() {
    if (_customerStep == 1) return _buildCustomerStep1();
    return _buildCustomerStep2();
  }

  Widget _buildCustomerStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Đăng nhập / Đăng ký', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('Nhập tên và số điện thoại để nhận mã OTP', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 20),
        _buildLabel('Họ tên'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(hintText: 'Nguyễn Văn A', prefixIcon: Icon(Icons.person_outline)),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 14),
        _buildLabel('Số điện thoại'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
          decoration: const InputDecoration(hintText: '0901234567', prefixIcon: Icon(Icons.phone_outlined)),
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _sendOtp(),
        ),
        if (_customerError != null) ...[const SizedBox(height: 8), Text(_customerError!, style: const TextStyle(color: AppColors.error, fontSize: 12))],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _customerLoading ? null : _sendOtp,
            child: _customerLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Gửi mã OTP'),
          ),
        ),
        const SizedBox(height: 16),
        Center(child: TextButton(onPressed: () => context.go(AppConstants.routeHome), child: const Text('Bỏ qua, vào xem menu'))),
      ],
    );
  }

  Widget _buildCustomerStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          GestureDetector(onTap: () => setState(() { _customerStep = 1; _customerError = null; }), child: const Icon(Icons.arrow_back_ios, size: 18, color: AppColors.primary)),
          const SizedBox(width: 8),
          Text('Nhập mã OTP', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 4),
        Text('Mã đã gửi đến ${_phoneController.text}', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 20),
        _buildLabel('Mã OTP (6 số)'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
          decoration: const InputDecoration(hintText: '• • • • • •', prefixIcon: Icon(Icons.lock_outline)),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 8),
          onChanged: (v) { if (v.length == 6) _verifyOtp(); },
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Hết hạn sau: ${_formatCountdown(_otpExpiry)}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          TextButton(
            onPressed: _otpCooldown > 0 ? null : _sendOtp,
            child: Text(_otpCooldown > 0 ? 'Gửi lại (${_otpCooldown}s)' : 'Gửi lại OTP', style: TextStyle(fontSize: 12, color: _otpCooldown > 0 ? AppColors.textSecondary : AppColors.primary)),
          ),
        ]),
        if (_customerError != null) ...[const SizedBox(height: 8), Text(_customerError!, style: const TextStyle(color: AppColors.error, fontSize: 12))],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            const Icon(Icons.info_outline, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text('Mã thử nghiệm: ${AppConstants.mockOtp}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ]),
        ),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: _customerLoading ? null : _verifyOtp,
          child: _customerLoading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Xác nhận OTP'),
        )),
      ],
    );
  }

  Widget _buildStaffTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Đăng nhập nhân viên', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('Dùng tài khoản nội bộ', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 20),
        _buildLabel('Tên đăng nhập'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _usernameController,
          decoration: const InputDecoration(hintText: 'username', prefixIcon: Icon(Icons.person_outline)),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 14),
        _buildLabel('Mật khẩu'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _passwordController,
          obscureText: !_staffPasswordVisible,
          decoration: InputDecoration(
            hintText: '••••••••',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(icon: Icon(_staffPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20), onPressed: () => setState(() => _staffPasswordVisible = !_staffPasswordVisible)),
          ),
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _staffLogin(),
        ),
        if (_staffError != null) ...[const SizedBox(height: 8), Text(_staffError!, style: const TextStyle(color: AppColors.error, fontSize: 12))],
        const SizedBox(height: 8),
        Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => context.push(AppConstants.routeForgotPassword), child: const Text('Quên mật khẩu?', style: TextStyle(fontSize: 12)))),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: _staffLoading ? null : _staffLogin,
          child: _staffLoading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Đăng nhập'),
        )),
        const SizedBox(height: 16),
        Center(child: TextButton(
          onPressed: () => context.push(AppConstants.routeRegister),
          child: const Text('Chưa có tài khoản? Đăng ký', style: TextStyle(fontSize: 13)),
        )),
      ],
    );
  }

  Widget _buildLabel(String text) => Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary));
}

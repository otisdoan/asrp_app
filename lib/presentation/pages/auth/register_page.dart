import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});
  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _agreeTerms = false;
  bool _passwordVisible = false;
  bool _confirmVisible = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String? _validate() {
    if (_usernameController.text.trim().length < 3) return 'Ten dang nhap toi thieu 3 ky tu';
    final pw = _passwordController.text;
    if (pw.length < 8) return 'Mat khau toi thieu 8 ky tu';
    if (!RegExp(r'[a-zA-Z]').hasMatch(pw)) return 'Mat khau phai bao gom chu cai';
    if (!RegExp(r'[0-9]').hasMatch(pw)) return 'Mat khau phai bao gom so';
    if (_confirmPasswordController.text != pw) return 'Mat khau xac nhan khong khop';
    final phone = _phoneController.text.trim();
    if (phone.isNotEmpty && !RegExp(r'^[0-9]{9,10}$').hasMatch(phone)) return 'So dien thoai khong hop le';
    final email = _emailController.text.trim();
    if (email.isNotEmpty && !RegExp(r'^[\w.-]+@[\w.-]+\.[a-z]{2,}$').hasMatch(email)) return 'Email khong hop le';
    if (!_agreeTerms) return 'Ban can dong y voi dieu khoan su dung';
    return null;
  }

  Future<void> _register() async {
    final err = _validate();
    if (err != null) { setState(() => _error = err); return; }
    setState(() { _loading = true; _error = null; });
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) context.go(AppConstants.routeHome);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Đăng ký tài khoản'), backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tạo tài khoản mới', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Đăng ký để đặt món và tích điểm thành viên', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 24),
              _buildLabel('Tên đăng nhập *'),
              const SizedBox(height: 6),
              TextFormField(controller: _usernameController, decoration: const InputDecoration(hintText: 'username', prefixIcon: Icon(Icons.person_outline)), textInputAction: TextInputAction.next),
              const SizedBox(height: 14),
              _buildLabel('Mật khẩu *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _passwordController,
                obscureText: !_passwordVisible,
                decoration: InputDecoration(hintText: 'Ít nhất 8 ký tự, có chữ và số', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(icon: Icon(_passwordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20), onPressed: () => setState(() => _passwordVisible = !_passwordVisible))),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              _buildLabel('Xác nhận mật khẩu *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_confirmVisible,
                decoration: InputDecoration(hintText: 'Nhập lại mật khẩu', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(icon: Icon(_confirmVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20), onPressed: () => setState(() => _confirmVisible = !_confirmVisible))),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              _buildLabel('Số điện thoại (tùy chọn)'),
              const SizedBox(height: 6),
              TextFormField(controller: _phoneController, keyboardType: TextInputType.phone, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)], decoration: const InputDecoration(hintText: '0901234567', prefixIcon: Icon(Icons.phone_outlined)), textInputAction: TextInputAction.next),
              const SizedBox(height: 14),
              _buildLabel('Email (tùy chọn)'),
              const SizedBox(height: 6),
              TextFormField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(hintText: 'example@email.com', prefixIcon: Icon(Icons.email_outlined)), textInputAction: TextInputAction.done),
              const SizedBox(height: 16),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Checkbox(value: _agreeTerms, onChanged: (v) => setState(() => _agreeTerms = v ?? false)),
                Expanded(child: Padding(padding: const EdgeInsets.only(top: 12), child: Text.rich(TextSpan(text: 'Tôi đồng ý với ', style: const TextStyle(fontSize: 13), children: [TextSpan(text: 'Điều khoản sử dụng', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)), const TextSpan(text: ' và '), TextSpan(text: 'Chính sách bảo mật', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600))]))))
              ]),
              if (_error != null) ...[const SizedBox(height: 8), Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 12))],
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: _loading ? null : _register,
                child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Đăng ký'),
              )),
              const SizedBox(height: 16),
              Center(child: TextButton(onPressed: () => context.pop(), child: const Text('Đã có tài khoản? Đăng nhập', style: TextStyle(fontSize: 13)))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary));
}

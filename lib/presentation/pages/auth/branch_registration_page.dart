import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/branch_registration_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/user_model.dart';


class BranchRegistrationPage extends ConsumerStatefulWidget {
  const BranchRegistrationPage({super.key});

  @override
  ConsumerState<BranchRegistrationPage> createState() => _BranchRegistrationPageState();
}

class _BranchRegistrationPageState extends ConsumerState<BranchRegistrationPage> {
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _formKey3 = GlobalKey<FormState>();

  int _currentStep = 1; // 1 to 4

  // Controllers
  late TextEditingController _brandNameCtrl;
  late TextEditingController _categoryCtrl;
  late TextEditingController _branchNameCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _gpsCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _taxCodeCtrl;
  late TextEditingController _bankNameCtrl;
  late TextEditingController _bankAccountCtrl;
  late TextEditingController _bankOwnerCtrl;

  // Focus Nodes for keyboard switching
  late FocusNode _brandNameFocus;
  late FocusNode _branchNameFocus;
  late FocusNode _addressFocus;
  late FocusNode _gpsFocus;
  late FocusNode _phoneFocus;
  late FocusNode _taxCodeFocus;
  late FocusNode _bankAccountFocus;
  late FocusNode _bankOwnerFocus;

  // Lĩnh vực kinh doanh list
  final List<String> _categories = [
    'F&B (Ẩm thực & Nhà hàng)',
    'Cà phê, Trà & Tráng miệng',
    'Ăn vặt & Xiên que',
    'Thực phẩm & Siêu thị mini',
    'Khác',
  ];

  @override
  void initState() {
    super.initState();

    // Initialize all controllers
    _brandNameCtrl = TextEditingController();
    _categoryCtrl = TextEditingController(text: _categories[0]);
    _branchNameCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    // Default GPS coordinate mock to make it feel premium
    _gpsCtrl = TextEditingController(text: '10.7769° N, 106.7009° E');
    _phoneCtrl = TextEditingController();
    _taxCodeCtrl = TextEditingController();
    _bankNameCtrl = TextEditingController(text: 'Vietcombank');
    _bankAccountCtrl = TextEditingController();
    _bankOwnerCtrl = TextEditingController();

    // Initialize all focus nodes
    _brandNameFocus = FocusNode();
    _branchNameFocus = FocusNode();
    _addressFocus = FocusNode();
    _gpsFocus = FocusNode();
    _phoneFocus = FocusNode();
    _taxCodeFocus = FocusNode();
    _bankAccountFocus = FocusNode();
    _bankOwnerFocus = FocusNode();

    // Schedule prefill if brand is already approved
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final registration = ref.read(branchRegistrationProvider);
      if (registration.status == 'approved') {
        setState(() {
          _currentStep = 2; // Direct to branch setup
          _brandNameCtrl.text = registration.brandName;
          _categoryCtrl.text = registration.category;
          _taxCodeCtrl.text = registration.taxCode;
          _bankNameCtrl.text = registration.bankName;
          _bankAccountCtrl.text = registration.bankAccount;
          _bankOwnerCtrl.text = registration.bankOwner;
        });
      }
    });
  }

  @override
  void dispose() {
    // Dispose all controllers
    _brandNameCtrl.dispose();
    _categoryCtrl.dispose();
    _branchNameCtrl.dispose();
    _addressCtrl.dispose();
    _gpsCtrl.dispose();
    _phoneCtrl.dispose();
    _taxCodeCtrl.dispose();
    _bankNameCtrl.dispose();
    _bankAccountCtrl.dispose();
    _bankOwnerCtrl.dispose();

    // Dispose all focus nodes
    _brandNameFocus.dispose();
    _branchNameFocus.dispose();
    _addressFocus.dispose();
    _gpsFocus.dispose();
    _phoneFocus.dispose();
    _taxCodeFocus.dispose();
    _bankAccountFocus.dispose();
    _bankOwnerFocus.dispose();

    super.dispose();
  }

  void _nextStep() {
    FocusScope.of(context).unfocus();
    final registration = ref.read(branchRegistrationProvider);
    if (_currentStep == 1) {
      if (_formKey1.currentState?.validate() ?? false) {
        setState(() {
          // Prefill branch name based on brand if empty
          if (_branchNameCtrl.text.isEmpty && _brandNameCtrl.text.isNotEmpty) {
            _branchNameCtrl.text = '${_brandNameCtrl.text} - Chi nhánh đầu tiên';
          }
          _currentStep = 2;
        });
      }
    } else if (_currentStep == 2) {
      if (_formKey2.currentState?.validate() ?? false) {
        setState(() {
          _currentStep = 3;
        });
      }
    } else if (_currentStep == 3) {
      final isApproved = registration.status == 'approved';
      if (isApproved || (_formKey3.currentState?.validate() ?? false)) {
        if (isApproved) {
          // Add additional branch
          ref.read(branchRegistrationProvider.notifier).registerNewBranch(
            branchName: _branchNameCtrl.text,
            phone: _phoneCtrl.text,
            address: _addressCtrl.text,
            gps: _gpsCtrl.text,
          );

          // Tự động nâng cấp vai trò thành SuperAdmin (Chủ chuỗi) do hệ thống đã có từ 2 chi nhánh trở lên
          final user = ref.read(currentUserProvider);
          if (user != null) {
            final updatedUser = UserModel(
              id: user.id,
              username: user.username,
              email: user.email,
              phone: user.phone,
              fullName: user.fullName,
              avatar: user.avatar,
              gender: user.gender,
              birthday: user.birthday,
              role: 'SuperAdmin',
              isActive: user.isActive,
              points: user.points,
              tier: user.tier,
              address: user.address,
              createdAt: user.createdAt,
              updatedAt: DateTime.now().toIso8601String(),
            );
            ref.read(authProvider.notifier).setUser(updatedUser);
          }
        } else {
          // First branch registration
          ref.read(branchRegistrationProvider.notifier).submitFirstBranch(
            brandName: _brandNameCtrl.text,
            category: _categoryCtrl.text,
            branchName: _branchNameCtrl.text,
            phone: _phoneCtrl.text,
            address: _addressCtrl.text,
            gps: _gpsCtrl.text,
            taxCode: _taxCodeCtrl.text,
            bankName: _bankNameCtrl.text,
            bankAccount: _bankAccountCtrl.text,
            bankOwner: _bankOwnerCtrl.text,
          );
        }
        setState(() {
          _currentStep = 4;
        });
      }
    }
  }

  void _prevStep() {
    FocusScope.of(context).unfocus();
    final registration = ref.read(branchRegistrationProvider);
    final isApproved = registration.status == 'approved';
    if (_currentStep > 2 || (_currentStep == 2 && !isApproved)) {
      setState(() {
        _currentStep--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic padding for keyboard avoidance
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final registration = ref.watch(branchRegistrationProvider);

    // If brand registration is pending approval, immediately intercept and show pending screen
    if (registration.status == 'pending') {
      return _buildPendingApprovalScreen();
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.bgMain,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: Text(
          registration.status == 'approved' ? 'Đăng ký chi nhánh mới' : 'Đăng ký chi nhánh',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            _buildProgressIndicator(),

            // Body Form
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: bottomInset + 32,
                ),
                child: _buildCurrentStepContent(),
              ),
            ),

            // Bottom Action Bar (Only for Step 1, 2, 3)
            if (_currentStep < 4) _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ─── Pending Approval Screen Intercept ──────────────────────────────────
  Widget _buildPendingApprovalScreen() {
    final registration = ref.watch(branchRegistrationProvider);

    return Scaffold(
      backgroundColor: AppColors.bgMain,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: const Text(
          'Đăng ký chi nhánh',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.bgSoft,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.15), width: 2),
                ),
                child: const Icon(
                  Icons.hourglass_empty_rounded,
                  color: AppColors.primary,
                  size: 60,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Hồ sơ đang chờ phê duyệt!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Thương hiệu & Chi nhánh đầu tiên đang được SuperAdmin kiểm tra. Vui lòng đợi đến khi được phê duyệt để tiếp tục đăng ký thêm chi nhánh khác.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.outlineVariant, width: 0.8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.assignment_outlined, color: AppColors.primary, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Tóm tắt thông tin đã gửi',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: AppColors.divider, height: 1),
                    const SizedBox(height: 12),
                    _buildSummaryRow('Thương hiệu', registration.brandName),
                    _buildSummaryRow('Lĩnh vực', registration.category),
                    _buildSummaryRow('Chi nhánh', registration.branchName),
                    _buildSummaryRow('Hotline chi nhánh', registration.phone),
                    _buildSummaryRow('Địa chỉ chi nhánh', registration.address),
                    _buildSummaryRow('Mã số thuế', registration.taxCode),
                    _buildSummaryRow('Đối soát', '${registration.bankName} - ${registration.bankAccount} (${registration.bankOwner.toUpperCase()})'),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Mock Approve button for easy testing!
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final isAlreadyApproved = registration.status == 'approved';
                    final newRole = isAlreadyApproved ? 'SuperAdmin' : 'Admin';

                    ref.read(branchRegistrationProvider.notifier).approveBrand();

                    final user = ref.read(currentUserProvider);
                    if (user != null) {
                      final updatedUser = UserModel(
                        id: user.id,
                        username: user.username,
                        email: user.email,
                        phone: user.phone,
                        fullName: user.fullName,
                        avatar: user.avatar,
                        gender: user.gender,
                        birthday: user.birthday,
                        role: newRole,
                        isActive: user.isActive,
                        points: user.points,
                        tier: user.tier,
                        address: user.address,
                        createdAt: user.createdAt,
                        updatedAt: DateTime.now().toIso8601String(),
                      );
                      await ref.read(authProvider.notifier).setUser(updatedUser);
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('🚨 [MOCK] Đã phê duyệt thương hiệu! Tài khoản của bạn được nâng cấp thành $newRole.'),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  icon: const Icon(Icons.gavel_rounded, color: Colors.white, size: 18),
                  label: const Text(
                    'Mock: Phê duyệt thương hiệu (SuperAdmin)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Back button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.outlineVariant),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Quay lại',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
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

  // ─── Progress Indicators ─────────────────────────────────────────────────
  Widget _buildProgressIndicator() {
    final registration = ref.watch(branchRegistrationProvider);
    final isApproved = registration.status == 'approved';

    final steps = isApproved
        ? ['Liên kết', 'Chi nhánh mới', 'Đối soát', 'Hoàn tất']
        : ['Thương hiệu', 'Chi nhánh', 'Đối soát', 'Chờ duyệt'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      color: AppColors.bgSoft.withValues(alpha: 0.4),
      child: Row(
        children: List.generate(steps.length, (index) {
          final stepNum = index + 1;
          final isCompleted = _currentStep > stepNum;
          final isActive = _currentStep == stepNum;

          Color circleColor = Colors.white;
          Color borderColor = AppColors.divider;
          Color textColor = AppColors.textTertiary;
          Widget innerWidget = Text(
            '$stepNum',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          );

          if (isCompleted) {
            circleColor = AppColors.successContainer;
            borderColor = AppColors.success;
            textColor = AppColors.success;
            innerWidget = const Icon(Icons.check_rounded, color: AppColors.success, size: 14);
          } else if (isActive) {
            circleColor = AppColors.primaryContainer;
            borderColor = AppColors.primary;
            textColor = AppColors.primary;
          }

          return Expanded(
            child: Row(
              children: [
                // Circle & Label
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: circleColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: borderColor, width: 1.5),
                      ),
                      child: Center(child: innerWidget),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      steps[index],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                // Connector line
                if (index < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 14, left: 4, right: 4),
                      color: _currentStep > stepNum ? AppColors.success : AppColors.divider,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ─── Step Dynamic Content Router ─────────────────────────────────────────
  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      case 4:
        return _buildStep4();
      default:
        return const SizedBox.shrink();
    }
  }

  // ─── Step 1: Brand Profile ────────────────────────────────────────────────
  Widget _buildStep1() {
    return Form(
      key: _formKey1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            icon: Icons.storefront_rounded,
            title: 'Hồ sơ thương hiệu đối tác',
            desc: 'Nhập thông tin cơ bản về thương hiệu của bạn để bắt đầu mở rộng hệ thống kinh doanh cùng chúng tôi.',
          ),
          const SizedBox(height: 20),

          // Brand name
          _buildTextField(
            label: 'Tên thương hiệu đối tác *',
            hint: 'Ví dụ: Phở Hùng Cựu Kim Sơn, Trà sữa DingTea...',
            controller: _brandNameCtrl,
            focusNode: _brandNameFocus,
            prefixIcon: Icons.business_outlined,
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập tên thương hiệu';
              }
              if (value.trim().length < 3) {
                return 'Tên thương hiệu phải có tối thiểu 3 ký tự';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Business Category Selector
          const Text(
            'Lĩnh vực kinh doanh chính *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _categoryCtrl.text.isEmpty ? _categories[0] : _categoryCtrl.text,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              prefixIcon: const Icon(Icons.restaurant_menu_outlined, color: AppColors.primary, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
            dropdownColor: Colors.white,
            style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
            items: _categories.map((cat) {
              return DropdownMenuItem<String>(
                value: cat,
                child: Text(cat),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _categoryCtrl.text = val;
                });
              }
            },
          ),
          const SizedBox(height: 24),

          // Note container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lưu ý: Tên thương hiệu sau khi đăng ký sẽ được SuperAdmin kiểm tra trùng lặp để bảo vệ bản quyền thương hiệu của bạn.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 2: First Branch Setup ──────────────────────────────────────────
  Widget _buildStep2() {
    final registration = ref.watch(branchRegistrationProvider);
    final isNewBranch = registration.status == 'approved';

    return Form(
      key: _formKey2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            icon: Icons.location_on_rounded,
            title: isNewBranch ? 'Đăng ký chi nhánh tiếp theo' : 'Chi nhánh đầu tiên',
            desc: isNewBranch
                ? 'Thiết lập thêm chi nhánh mới dưới thương hiệu đã được phê duyệt của bạn.'
                : 'Thiết lập địa điểm đầu tiên của chuỗi. Khách hàng sẽ nhìn thấy và đặt món dựa theo định vị chi nhánh này.',
          ),
          const SizedBox(height: 20),

          // Branch name
          _buildTextField(
            label: 'Tên chi nhánh của bạn *',
            hint: 'Ví dụ: DineX - Quận 1, DineX - Hai Bà Trưng...',
            controller: _branchNameCtrl,
            focusNode: _branchNameFocus,
            prefixIcon: Icons.storefront_outlined,
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập tên chi nhánh';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Phone/Hotline
          _buildTextField(
            label: 'Số điện thoại hotline chi nhánh *',
            hint: 'Nhập số điện thoại liên hệ (Ví dụ: 0987654321)',
            controller: _phoneCtrl,
            focusNode: _phoneFocus,
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_outlined,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập số điện thoại hotline';
              }
              final cleanVal = value.replaceAll(RegExp(r'\s+'), '');
              if (cleanVal.length < 10 || cleanVal.length > 11) {
                return 'Số điện thoại liên hệ phải có 10 hoặc 11 chữ số';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Address
          _buildTextField(
            label: 'Địa chỉ hoạt động chi tiết *',
            hint: 'Số nhà, Tên đường, Phường/Xã, Quận/Huyện...',
            controller: _addressCtrl,
            focusNode: _addressFocus,
            prefixIcon: Icons.map_outlined,
            textCapitalization: TextCapitalization.sentences,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập địa chỉ chi nhánh';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // GPS Coordinates (Coordinates can be mock or custom)
          _buildTextField(
            label: 'Tọa độ GPS (Vĩ độ - Kinh độ) *',
            hint: 'Tọa độ địa lý để hiển thị bản đồ và tính khoảng cách ship',
            controller: _gpsCtrl,
            focusNode: _gpsFocus,
            prefixIcon: Icons.gps_fixed_outlined,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng điền tọa độ GPS chi nhánh';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  // ─── Step 3: Legal & Settlement ──────────────────────────────────────────
  Widget _buildStep3() {
    final registration = ref.watch(branchRegistrationProvider);
    final isApproved = registration.status == 'approved';

    if (isApproved) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            icon: Icons.verified_user_rounded,
            title: 'Hồ sơ pháp lý liên kết',
            desc: 'Thông tin pháp lý & tài khoản ngân hàng đối soát của thương hiệu đã được duyệt và kế thừa đầy đủ.',
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.successContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.success, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Hồ sơ pháp lý hợp lệ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSummaryRow('Thương hiệu', registration.brandName),
                _buildSummaryRow('Mã số thuế', registration.taxCode),
                _buildSummaryRow('Ngân hàng', registration.bankName),
                _buildSummaryRow('Số tài khoản', registration.bankAccount),
                _buildSummaryRow('Chủ tài khoản', registration.bankOwner.toUpperCase()),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Nhấn "Gửi hồ sơ đăng ký" để gửi yêu cầu phê duyệt chi nhánh mới này lên hệ thống DineX.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
          ),
        ],
      );
    }

    return Form(
      key: _formKey3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            icon: Icons.account_balance_outlined,
            title: 'Hồ sơ pháp lý & Đối soát tài chính',
            desc: 'Nhập thông tin thuế và tài khoản ngân hàng để hệ thống tự động thanh toán đối soát doanh thu chi nhánh định kỳ.',
          ),
          const SizedBox(height: 20),

          // Tax Code
          _buildTextField(
            label: 'Mã số thuế doanh nghiệp / hộ kinh doanh *',
            hint: 'Nhập mã số thuế (10 hoặc 13 chữ số)',
            controller: _taxCodeCtrl,
            focusNode: _taxCodeFocus,
            keyboardType: TextInputType.number,
            prefixIcon: Icons.description_outlined,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập mã số thuế';
              }
              final cleanVal = value.replaceAll(RegExp(r'\s+'), '');
              if (cleanVal.length != 10 && cleanVal.length != 13) {
                return 'Mã số thuế phải có độ dài đúng 10 hoặc 13 chữ số';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Bank Name dropdown
          const Text(
            'Tên ngân hàng đối soát *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _bankNameCtrl.text.isEmpty ? 'Vietcombank' : _bankNameCtrl.text,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              prefixIcon: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
            dropdownColor: Colors.white,
            style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
            items: ['Vietcombank', 'BIDV', 'Techcombank', 'VietinBank', 'MB Bank', 'ACB'].map((bank) {
              return DropdownMenuItem<String>(
                value: bank,
                child: Text(bank),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _bankNameCtrl.text = val;
                });
              }
            },
          ),
          const SizedBox(height: 16),

          // Bank Account Number
          _buildTextField(
            label: 'Số tài khoản ngân hàng đối soát *',
            hint: 'Nhập số tài khoản nhận tiền doanh thu',
            controller: _bankAccountCtrl,
            focusNode: _bankAccountFocus,
            keyboardType: TextInputType.number,
            prefixIcon: Icons.credit_card_outlined,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập số tài khoản ngân hàng';
              }
              if (value.length < 6) {
                return 'Số tài khoản ngân hàng không hợp lệ';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Bank Account Owner Name
          _buildTextField(
            label: 'Tên chủ tài khoản ngân hàng *',
            hint: 'Viết hoa không dấu (Ví dụ: NGUYEN VAN A)',
            controller: _bankOwnerCtrl,
            focusNode: _bankOwnerFocus,
            prefixIcon: Icons.person_outline_rounded,
            textCapitalization: TextCapitalization.characters,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập tên chủ tài khoản ngân hàng';
              }
              if (value.trim().split(' ').length < 2) {
                return 'Tên chủ tài khoản ngân hàng đầy đủ gồm họ và tên';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  // ─── Step 4: Complete/Pending Approval Screen ────────────────────────────
  Widget _buildStep4() {
    final registration = ref.watch(branchRegistrationProvider);
    final hasMultipleBranches = registration.registeredBranches.length > 1;

    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.successContainer,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.success.withValues(alpha: 0.2), width: 2),
          ),
          child: const Icon(
            Icons.verified_rounded,
            color: AppColors.success,
            size: 60,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          hasMultipleBranches ? 'Đăng ký chi nhánh mới hoàn tất!' : 'Đăng ký hồ sơ hoàn tất!',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          hasMultipleBranches
              ? 'Yêu cầu mở thêm chi nhánh mới của bạn đang được kiểm tra. Kết quả phê duyệt chi nhánh sẽ được cập nhật nhanh chóng.'
              : 'Hồ sơ của bạn đang được hệ thống SuperAdmin kiểm tra và phê duyệt. Kết quả sẽ được gửi thông báo đến bạn sau tối đa 24 giờ làm việc.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),

        // Beautiful Summary registered data card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outlineVariant, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.assignment_outlined, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    hasMultipleBranches ? 'Chi nhánh vừa đăng ký' : 'Tóm tắt thông tin đã gửi',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: 12),
              if (hasMultipleBranches) ...[
                _buildSummaryRow('Thương hiệu chủ quản', registration.brandName),
                _buildSummaryRow('Tên chi nhánh mới', _branchNameCtrl.text),
                _buildSummaryRow('Hotline liên hệ', _phoneCtrl.text),
                _buildSummaryRow('Địa chỉ hoạt động', _addressCtrl.text),
                _buildSummaryRow('Tọa độ GPS', _gpsCtrl.text),
                const SizedBox(height: 12),
                const Divider(color: AppColors.divider, height: 1),
                const SizedBox(height: 12),
                Text(
                  'Danh sách chi nhánh thuộc chuỗi (${registration.registeredBranches.length}):',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                ...registration.registeredBranches.map((br) => Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${br['branchName']} - ${br['address']}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                )),
              ] else ...[
                _buildSummaryRow('Thương hiệu', _brandNameCtrl.text),
                _buildSummaryRow('Lĩnh vực', _categoryCtrl.text),
                _buildSummaryRow('Chi nhánh', _branchNameCtrl.text),
                _buildSummaryRow('Hotline chi nhánh', _phoneCtrl.text),
                _buildSummaryRow('Địa chỉ chi nhánh', _addressCtrl.text),
                _buildSummaryRow('Mã số thuế', _taxCodeCtrl.text),
                _buildSummaryRow('Đối soát', '${_bankNameCtrl.text} - ${_bankAccountCtrl.text} (${_bankOwnerCtrl.text.toUpperCase()})'),
              ],
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Close and complete button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              context.pop();
              // Show notification to user
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(hasMultipleBranches 
                      ? 'Chi nhánh mới đã được gửi phê duyệt thành công!' 
                      : 'Hồ sơ đối tác đã được lưu trữ trên hệ thống thành công!'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 2,
            ),
            child: const Text(
              'Hoàn tất & Quay về',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'Chưa nhập',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step Header helper ──────────────────────────────────────────────────
  Widget _buildStepHeader({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.bgSoft,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Custom TextFormField Builder ────────────────────────────────────────
  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required FocusNode focusNode,
    IconData? prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: AppColors.textTertiary),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: AppColors.primary, size: 20)
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
            errorStyle: const TextStyle(fontSize: 11, color: AppColors.error),
          ),
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  // ─── Bottom Actions Bar ───────────────────────────────────────────────────
  Widget _buildBottomBar() {
    final registration = ref.watch(branchRegistrationProvider);
    final isApproved = registration.status == 'approved';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 0.8),
        ),
      ),
      child: Row(
        children: [
          // Prev button (Visible if Step > 1 or not approved step 2)
          if (_currentStep > 2 || (_currentStep == 2 && !isApproved)) ...[
            Expanded(
              flex: 2,
              child: OutlinedButton(
                onPressed: _prevStep,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary, width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: AppColors.bgSoft,
                ),
                child: const Text(
                  'Quay lại',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],

          // Next / Submit button
          Expanded(
            flex: 3,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 1,
              ),
              child: Text(
                _currentStep == 3 
                    ? (isApproved ? 'Gửi hồ sơ chi nhánh mới' : 'Gửi hồ sơ đăng ký') 
                    : 'Tiếp tục',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

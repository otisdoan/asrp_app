import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/branch_registration_provider.dart';
import '../../../providers/branch_provider.dart';
import '../../../core/utils/top_notification.dart';
import '../../../providers/staff_management_provider.dart';
import '../../../data/models/staff_member_model.dart';
import '../../../data/models/branch_model.dart';

String _formatPhone(String phone) {
  final clean = phone.trim();
  if (clean.startsWith('+84')) {
    return '0${clean.substring(3)}';
  }
  if (clean.startsWith('84') && clean.length > 9) {
    return '0${clean.substring(2)}';
  }
  return clean;
}

String _parseError(dynamic e) {
  String errorMsg = e.toString().replaceAll('Exception: ', '');
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final msg = data['detail'] ?? 
                  data['Detail'] ?? 
                  data['message'] ?? 
                  data['error'] ?? 
                  data['title'] ?? 
                  data['Title'];
      if (msg != null) {
        errorMsg = msg.toString();
      }
    }
  }

  if (errorMsg.contains('SuperAdmin/Admin users cannot be assigned') ||
      errorMsg.contains('Admin or SuperAdmin cannot be assigned')) {
    return 'Tài khoản này là Chủ thương hiệu (Admin/SuperAdmin), không thể bổ nhiệm làm nhân sự chi nhánh.';
  }
  if (errorMsg.contains('Inactive users cannot be assigned')) {
    return 'Tài khoản này đang bị vô hiệu hóa, vui lòng kích hoạt lại trước.';
  }
  if (errorMsg.contains('Phone number is already registered')) {
    return 'Số điện thoại này đã được đăng ký bởi tài khoản khác.';
  }
  
  return errorMsg;
}

class StaffManagementPage extends ConsumerStatefulWidget {
  const StaffManagementPage({super.key});

  @override
  ConsumerState<StaffManagementPage> createState() =>
      _StaffManagementPageState();
}

class _StaffManagementPageState extends ConsumerState<StaffManagementPage> {
  List<String> _branchOptions = [];
  Map<String, String> _branchNameToId = {};
  List<BranchListItemModel> _realBranches = [];
  bool _isInitialized = false;

  // Search state and controller
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  // Loading state
  bool _isLoadingStaff = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(myBrandBranchesFutureProvider);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchStaffList() async {
    setState(() {
      _isLoadingStaff = true;
    });

    final notifier = ref.read(staffManagementProvider.notifier);
    final user = ref.read(currentUserProvider);
    final registration = ref.read(branchRegistrationProvider);
    final role = user?.role.toLowerCase();
    final canManageManagers = role == 'superadmin' || role == 'admin';

    try {
      if (canManageManagers) {
        try {
          final results = await Future.wait(
              _realBranches.map((b) => notifier.getStaffListForBranch(b.id)));
          final combined = results.expand((list) => list).toList();
          notifier.setStaffList(combined);
        } catch (e) {
          print(
              '[StaffManagementPage] Error fetching staff for all branches: $e');
        }
      } else {
        final bId = role == 'manager'
            ? user?.branchId
            : user?.branchId ?? registration.approvedFirstBranchId;
        if (bId != null && bId.isNotEmpty) {
          await notifier.fetchStaffMembers(bId);
        } else if (role != 'manager') {
          if (_realBranches.isNotEmpty) {
            await notifier.fetchStaffMembers(_realBranches.first.id);
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStaff = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final registration = ref.watch(branchRegistrationProvider);
    final role = user?.role.toLowerCase();
    final canManageManagers = role == 'superadmin' || role == 'admin';
    final canManageStaff = canManageManagers || role == 'manager';

    // Chi nhánh của Admin/Manager
    String adminBranch = 'Quận 1';
    final userBranchId = user?.branchId;
    if (userBranchId != null) {
      final userBranch = _realBranches.any((b) => b.id == userBranchId)
          ? _realBranches.firstWhere((b) => b.id == userBranchId)
          : null;
      if (userBranch != null) {
        adminBranch = userBranch.name;
      }
    } else if (registration.registeredBranches.isNotEmpty) {
      adminBranch =
          registration.registeredBranches.first['branchName'] ?? 'Quận 1';
    } else if (_realBranches.isNotEmpty) {
      adminBranch = _realBranches.first.name;
    }

    final branchesAsyncValue = ref.watch(myBrandBranchesFutureProvider);

    branchesAsyncValue.whenData((branches) {
      _realBranches = branches;
      final List<String> options = [];
      final Map<String, String> nameToId = {};

      for (int i = 0; i < branches.length; i++) {
        final b = branches[i];
        String displayName = b.name;
        final duplicateCount = branches.where((x) => x.name == b.name).length;
        if (duplicateCount > 1) {
          if (b.address != null && b.address!.isNotEmpty) {
            displayName = '${b.name} (${b.address})';
          } else {
            displayName = '${b.name} (#${i + 1})';
          }
        }
        options.add(displayName);
        nameToId[displayName] = b.id;
        nameToId[b.name] = b.id;
        nameToId[b.id] = b.id;
      }

      _branchOptions = options;
      _branchNameToId = nameToId;

      if (!_isInitialized) {
        _isInitialized = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _fetchStaffList();
        });
      }
    });

    // Lấy toàn bộ danh sách từ provider
    final rawStaffList = ref.watch(staffManagementProvider);

    // Lọc danh sách nhân viên tương ứng theo quyền
    List<StaffMemberModel> filteredList = [];
    filteredList = rawStaffList;

    // Lọc tiếp theo từ khóa tìm kiếm
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();
      filteredList = filteredList.where((m) {
        final cleanPhone = m.phone.replaceAll(RegExp(r'\D'), '');
        final cleanQuery = query.replaceAll(RegExp(r'\D'), '');
        
        if (cleanQuery.isNotEmpty && RegExp(r'^\d+$').hasMatch(cleanQuery)) {
          final matchNormal = cleanPhone.contains(cleanQuery);
          
          String normalizedPhone = cleanPhone;
          if (normalizedPhone.startsWith('84')) {
            normalizedPhone = '0${normalizedPhone.substring(2)}';
          }
          final matchNormalized = normalizedPhone.contains(cleanQuery);
          
          return matchNormal || matchNormalized;
        }
        
        return m.fullName.toLowerCase().contains(query) ||
            m.phone.toLowerCase().contains(query);
      }).toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          canManageManagers
              ? 'Phân công Quản lý chi nhánh'
              : 'Quản lý nhân sự chi nhánh',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            // ─── Premium Search Bar ─────────────────────────────────────────────
            _buildSearchBar(),

            // ─── Staff List Directory ──────────────────────────────────────────
            Expanded(
              child: branchesAsyncValue.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (err, stack) =>
                    Center(child: Text('Lỗi tải chi nhánh: $err')),
                data: (_) {
                  if (_isLoadingStaff) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                  }
                  if (filteredList.isEmpty) {
                    return _buildEmptyState();
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final member = filteredList[index];
                      return _buildStaffCard(member, canManageManagers, adminBranch);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // ─── FAB: Add new staff member ─────────────────────────────────────────
      floatingActionButton: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFFF95C40)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: canManageStaff
                ? () => _openStaffDialog(null, canManageManagers, adminBranch)
                : null,
            borderRadius: BorderRadius.circular(26),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_add_alt_1_rounded, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    canManageManagers ? 'Bổ nhiệm Quản lý chi nhánh' : 'Thêm nhân viên mới',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Premium Search Bar UI ───────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      key: const ValueKey('staff_search_bar_padding'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF0F1F3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          key: const ValueKey('staff_search_field'),
          controller: _searchController,
          focusNode: _searchFocusNode,
          onChanged: (val) {
            setState(() {
              _searchQuery = val;
            });
          },
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: 'Tìm kiếm nhân viên...',
            hintStyle:
                const TextStyle(color: AppColors.textPlaceholder, fontSize: 13),
            prefixIcon: const Icon(Icons.search_rounded,
                color: AppColors.textSecondary, size: 22),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.cancel_rounded,
                        color: AppColors.textTertiary, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  // ─── Staff Card Item Widget ───────────────────────────────────────────────
  Widget _buildStaffCard(
      StaffMemberModel member, bool isSuperAdmin, String adminBranch) {
    Color badgeBgColor;
    Color badgeTextColor;
    String displayRole;
    LinearGradient avatarGradient;

    switch (member.role.trim().toLowerCase()) {
      case 'admin':
        badgeBgColor = const Color(0xFFFEF2F2);
        badgeTextColor = const Color(0xFFEF4444);
        displayRole = 'Chủ thương hiệu';
        avatarGradient = const LinearGradient(
          colors: [Color(0xFFFCA5A5), Color(0xFFEF4444)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        break;
      case 'manager':
        badgeBgColor = const Color(0xFFFFF7ED);
        badgeTextColor = const Color(0xFFF97316);
        displayRole = 'Quản lý / Thu ngân';
        avatarGradient = const LinearGradient(
          colors: [Color(0xFFFDBA74), Color(0xFFF97316)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        break;
      case 'staff':
      default:
        badgeBgColor = const Color(0xFFECFDF5);
        badgeTextColor = const Color(0xFF10B981);
        displayRole = 'Phục vụ';
        avatarGradient = const LinearGradient(
          colors: [Color(0xFF6EE7B7), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }

    final trimmedName = member.fullName.trim();
    final initials = trimmedName.isNotEmpty
        ? trimmedName.split(' ').last.substring(0, 1).toUpperCase()
        : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F1F3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Premium Gradient Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: avatarGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: avatarGradient.colors.last.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Info Detail
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          member.fullName.isNotEmpty
                              ? member.fullName
                              : 'Chưa cập nhật tên',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Branch Badge (Visible to SuperAdmin)
                      if (isSuperAdmin)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            member.branchName,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.phone_iphone_rounded,
                          size: 13, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Text(
                        _formatPhone(member.phone),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Role Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeBgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      displayRole,
                      style: TextStyle(
                        color: badgeTextColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Actions (Premium Circular Buttons with Clean Spacing)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Edit Circular Button
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3F4F6),
                    shape: BoxShape.circle,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _openStaffDialog(member, isSuperAdmin, adminBranch),
                      customBorder: const CircleBorder(),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: AppColors.textSecondary,
                        size: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Delete Circular Button
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEF2F2),
                    shape: BoxShape.circle,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _confirmDelete(member),
                      customBorder: const CircleBorder(),
                      child: const Icon(
                        Icons.delete_rounded,
                        color: Colors.redAccent,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  // ─── Add/Edit Custom Dialog Sheet ──────────────────────────────────────────
  void _openStaffDialog(
      StaffMemberModel? existing, bool canManageManagers, String adminBranch) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: _StaffEditorSheetContent(
            existing: existing,
            canManageManagers: canManageManagers,
            adminBranch: adminBranch,
            branchOptions: _branchOptions,
            branchNameToId: _branchNameToId,
            onSaveSuccess: () {
              _fetchStaffList();
            },
          ),
        );
      },
    );
  }

  // ─── Delete Confirmation Dialog ────────────────────────────────────────────
  void _confirmDelete(StaffMemberModel member) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
              SizedBox(width: 8),
              Text(
                'Xóa tài khoản nhân sự?',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              ),
            ],
          ),
          content: Text(
            'Bạn có chắc chắn muốn xóa nhân sự "${member.fullName}" ra khỏi hệ thống chi nhánh không? Nhân viên này sẽ không thể tiếp tục đăng nhập bán hàng.',
            style:
                const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(ctx);
                try {
                  final bId = _branchNameToId[member.branchName] ??
                      ref.read(staffManagementProvider.notifier).activeBranchId;
                  if (bId != null) {
                    await ref
                        .read(staffManagementProvider.notifier)
                        .toggleStaffStatus(member.id, false, targetBranchId: bId);
                    await _fetchStaffList();
                  }
                  navigator.pop();
                  TopNotification.show(
                    context,
                    message: 'Đã vô hiệu hóa nhân sự thành công.',
                  );
                } catch (e) {
                  navigator.pop();
                  TopNotification.show(
                    context,
                    message: 'Lỗi khi vô hiệu hóa: ${_parseError(e)}',
                    isError: true,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Xác nhận xóa'),
            ),
          ],
        );
      },
    );
  }

  // ─── Empty Directory Layout UI ─────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.bgSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people_outline_rounded,
                size: 36, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 16),
          const Text(
            'Danh sách trống',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              'Chưa có nhân sự nào được bổ nhiệm cho chi nhánh này.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffEditorSheetContent extends ConsumerStatefulWidget {
  final StaffMemberModel? existing;
  final bool canManageManagers;
  final String adminBranch;
  final List<String> branchOptions;
  final Map<String, String> branchNameToId;
  final VoidCallback onSaveSuccess;

  const _StaffEditorSheetContent({
    this.existing,
    required this.canManageManagers,
    required this.adminBranch,
    required this.branchOptions,
    required this.branchNameToId,
    required this.onSaveSuccess,
  });

  @override
  ConsumerState<_StaffEditorSheetContent> createState() =>
      _StaffEditorSheetContentState();
}

class _StaffEditorSheetContentState
    extends ConsumerState<_StaffEditorSheetContent> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;
  late String _selectedRole;
  late String _selectedBranch;

  String? _resolvedUserId;
  bool _isCheckingPhone = false;
  bool _phoneExists = false;
  bool _phoneLookupFailed = false;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.existing?.fullName ?? '');
    _phoneController =
        TextEditingController(text: widget.existing?.phone ?? '');
    _passwordController = TextEditingController();

    _selectedRole = widget.existing?.role ?? 'Staff';
    if (_selectedRole == 'Admin' || (!widget.canManageManagers && _selectedRole == 'Manager')) {
      _selectedRole = 'Staff';
    }

    final initialBranch = widget.existing?.branchName;
    if (initialBranch != null && initialBranch.isNotEmpty) {
      if (widget.branchOptions.contains(initialBranch)) {
        _selectedBranch = initialBranch;
      } else {
        final matched = widget.branchOptions.firstWhere(
          (b) => b.toLowerCase().startsWith(initialBranch.toLowerCase()) ||
                 initialBranch.toLowerCase().startsWith(b.toLowerCase()),
          orElse: () => widget.branchOptions.isNotEmpty ? widget.branchOptions[0] : initialBranch,
        );
        _selectedBranch = matched;
      }
    } else {
      _selectedBranch = widget.canManageManagers
          ? (widget.branchOptions.isNotEmpty ? widget.branchOptions[0] : widget.adminBranch)
          : widget.adminBranch;
    }

    if (widget.existing == null) {
      _phoneController.addListener(_onPhoneChanged);
    }
  }

  void _onPhoneChanged() {
    final phone = _phoneController.text.trim();
    if (phone.length == 10) {
      _checkPhone(phone);
    } else {
      if (_phoneExists || _phoneLookupFailed || _resolvedUserId != null) {
        setState(() {
          _phoneExists = false;
          _phoneLookupFailed = false;
          _resolvedUserId = null;
        });
      }
    }
  }

  Future<void> _checkPhone(String phone) async {
    if (_isCheckingPhone) return;
    setState(() {
      _isCheckingPhone = true;
      _phoneLookupFailed = false;
    });

    try {
      final notifier = ref.read(staffManagementProvider.notifier);
      final userMap = await notifier.checkPhoneExists(phone);
      if (userMap != null) {
        setState(() {
          _phoneExists = true;
          _phoneLookupFailed = false;
          _resolvedUserId = userMap['id']?.toString();
          final String resolvedName = userMap['fullName']?.toString() ??
              userMap['username']?.toString() ??
              '';
          if (resolvedName.isNotEmpty) {
            _nameController.text = resolvedName;
          }
        });
      } else {
        setState(() {
          _phoneExists = false;
          _phoneLookupFailed = false;
          _resolvedUserId = null;
        });
      }
    } catch (_) {
      setState(() {
        _phoneExists = false;
        _phoneLookupFailed = true;
        _resolvedUserId = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingPhone = false;
        });
      }
    }
  }

  @override
  void dispose() {
    if (widget.existing == null) {
      _phoneController.removeListener(_onPhoneChanged);
    }
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return _KeyboardAvoidPadding(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4.5,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit
                        ? 'Chỉnh sửa thông tin'
                        : (widget.canManageManagers
                            ? 'Bổ nhiệm nhân sự mới'
                            : 'Thêm nhân viên mới'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),

            // Form Content
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. Phone number field (Always first if not edit)
                    if (!isEdit) ...[
                      const Text(
                        'Số điện thoại đăng nhập *',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          hintText: 'Nhập số điện thoại...',
                          hintStyle: const TextStyle(
                              color: AppColors.textPlaceholder, fontSize: 13),
                          prefixIcon: const Icon(Icons.phone_iphone_rounded,
                              color: AppColors.primary, size: 20),
                          suffixIcon: _isCheckingPhone
                              ? const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                          AppColors.primary),
                                    ),
                                  ),
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.outlineVariant),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 1.5),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.error, width: 1.0),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.error, width: 1.5),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Vui lòng nhập số điện thoại';
                          }
                          if (val.length < 9) {
                            return 'Số điện thoại tối thiểu 9 chữ số';
                          }
                          return null;
                        },
                      ),
                      if (_phoneExists) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Tìm thấy tài khoản trên hệ thống',
                                      style: TextStyle(
                                          color: Colors.green.shade900,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '• Họ và tên: ${_nameController.text}',
                                style: TextStyle(
                                    color: Colors.green.shade900,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '• Trạng thái: Hợp lệ để bổ nhiệm làm nhân sự.',
                                style: TextStyle(
                                    color: Colors.green.shade900,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ] else if (_phoneLookupFailed &&
                          !_isCheckingPhone) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline_rounded,
                                  color: Colors.red.shade800, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Không thể kiểm tra số điện thoại lúc này. Vui lòng thử lại.',
                                  style: TextStyle(
                                      color: Colors.red.shade900,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (_phoneController.text.trim().length == 10 &&
                          !_isCheckingPhone) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline_rounded,
                                  color: Colors.red.shade800, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Số điện thoại chưa đăng ký tài khoản. Vui lòng đăng ký trước khi bổ nhiệm.',
                                  style: TextStyle(
                                      color: Colors.red.shade900,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],

                    // 2. Profile card (Only shown in Edit mode to display read-only user info)
                    if (isEdit) ...[
                      const Text(
                        'Thông tin nhân sự',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _nameController.text.isNotEmpty
                                        ? _nameController.text
                                        : 'Chưa cập nhật tên',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Số điện thoại: ${_formatPhone(_phoneController.text)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],



                    // 3. Branch selection dropdown (only for brand owner, lock to admin branch for standard admin)
                    if (widget.canManageManagers) ...[
                      const Text(
                        'Chi nhánh làm việc *',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Builder(
                        builder: (context) {
                          final effectiveOptions = List<String>.from(widget.branchOptions);
                          if (_selectedBranch.isNotEmpty && !effectiveOptions.contains(_selectedBranch)) {
                            effectiveOptions.add(_selectedBranch);
                          }
                          return DropdownButtonFormField<String>(
                            initialValue: _selectedBranch,
                            dropdownColor: Colors.white,
                            style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.storefront_outlined,
                                  color: AppColors.primary, size: 20),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 16),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: AppColors.outlineVariant),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: AppColors.primary, width: 1.5),
                              ),
                            ),
                            items: effectiveOptions.map((branch) {
                              return DropdownMenuItem<String>(
                                value: branch,
                                child: Text(branch),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedBranch = val;
                                });
                              }
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                     // 4. Role choice chips
                    ...[
                      const Text(
                        'Phân vai trò nhân viên *',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          // Card 1: Staff (Nhân viên)
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedRole = 'Staff'),
                              child: Container(
                                height: 52,
                                decoration: BoxDecoration(
                                  color: _selectedRole == 'Staff'
                                      ? const Color(0xFFECFDF5)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _selectedRole == 'Staff'
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFE5E7EB),
                                    width: _selectedRole == 'Staff' ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.badge_rounded,
                                      color: _selectedRole == 'Staff'
                                          ? const Color(0xFF10B981)
                                          : AppColors.textSecondary,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Nhân viên',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: _selectedRole == 'Staff'
                                            ? const Color(0xFF047857)
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Card 2: Manager (Thu ngân / Quản lý)
                          Expanded(
                            child: GestureDetector(
                              onTap: widget.canManageManagers
                                  ? () => setState(() => _selectedRole = 'Manager')
                                  : null,
                              child: Container(
                                height: 52,
                                decoration: BoxDecoration(
                                  color: _selectedRole == 'Manager'
                                      ? const Color(0xFFFFF7ED)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _selectedRole == 'Manager'
                                        ? const Color(0xFFF97316)
                                        : const Color(0xFFE5E7EB),
                                    width: _selectedRole == 'Manager' ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.admin_panel_settings_rounded,
                                      color: _selectedRole == 'Manager'
                                          ? const Color(0xFFF97316)
                                          : AppColors.textSecondary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Thu ngân / Quản lý',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: _selectedRole == 'Manager'
                                            ? const Color(0xFFC2410C)
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 28),

                    // Bottom buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: const BorderSide(
                                  color: AppColors.outlineVariant),
                            ),
                            child: const Text(
                              'Hủy bỏ',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: (widget.existing == null &&
                                    !_phoneExists)
                                ? null
                                : () async {
                                    if (_formKey.currentState!.validate()) {
                                      final notifier = ref.read(
                                          staffManagementProvider.notifier);
                                      final navigator = Navigator.of(context);

                                      try {
                                        if (widget.existing == null) {
                                          final targetBranchId =
                                              widget.branchNameToId[
                                                      _selectedBranch] ??
                                                  notifier.activeBranchId;

                                          final newMember = StaffMemberModel(
                                            id: '',
                                            fullName:
                                                _nameController.text.trim(),
                                            phone: _phoneController.text.trim(),
                                            role: _selectedRole,
                                            branchName: _selectedBranch,
                                            createdAt: DateTime.now()
                                                .toIso8601String(),
                                          );
                                          await notifier.addStaffMember(
                                            newMember,
                                            targetBranchId: targetBranchId,
                                            existingUserId: _resolvedUserId,
                                          );
                                        } else {
                                          final originalBranchId =
                                              widget.existing!.branchId ??
                                              widget.branchNameToId[
                                                      widget.existing!
                                                          .branchName] ??
                                                  notifier.activeBranchId ??
                                                  '';
                                          final targetBranchId =
                                              widget.branchNameToId[
                                                      _selectedBranch] ??
                                                  notifier.activeBranchId ??
                                                  '';

                                          final updated =
                                              widget.existing!.copyWith(
                                            fullName:
                                                _nameController.text.trim(),
                                            phone: _phoneController.text.trim(),
                                            role: _selectedRole,
                                            branchName: _selectedBranch,
                                          );
                                          await notifier.updateStaffMember(
                                            updated,
                                            originalBranchId: originalBranchId,
                                            targetBranchId: targetBranchId,
                                            originalRole: widget.existing!.role,
                                          );
                                        }

                                        widget.onSaveSuccess();
                                        navigator.pop();

                                        TopNotification.show(
                                          context,
                                          message: widget.existing == null
                                              ? 'Đã thêm thành công nhân sự mới.'
                                              : 'Đã cập nhật thông tin nhân viên.',
                                        );
                                      } catch (e) {
                                        TopNotification.show(
                                          context,
                                          message: 'Lỗi: ${_parseError(e)}',
                                          isError: true,
                                        );
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              isEdit ? 'Lưu thay đổi' : 'Thêm nhân sự',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeyboardAvoidPadding extends StatelessWidget {
  final Widget child;
  const _KeyboardAvoidPadding({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: child,
    );
  }
}

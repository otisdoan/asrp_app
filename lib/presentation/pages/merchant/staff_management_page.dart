import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/branch_registration_provider.dart';
import '../../../providers/branch_provider.dart';
import '../../../core/utils/top_notification.dart';
import '../../../providers/staff_management_provider.dart';
import '../../../data/models/staff_member_model.dart';
import '../../../data/models/branch_model.dart';

class StaffManagementPage extends ConsumerStatefulWidget {
  const StaffManagementPage({super.key});

  @override
  ConsumerState<StaffManagementPage> createState() =>
      _StaffManagementPageState();
}

class _StaffManagementPageState extends ConsumerState<StaffManagementPage> with WidgetsBindingObserver {
  // Lọc chi nhánh dành cho SuperAdmin: 'Tất cả' | các chi nhánh động
  String _selectedBranchTab = 'Tất cả';
  List<String> _branchOptions = [];
  Map<String, String> _branchNameToId = {};
  List<BranchListItemModel> _realBranches = [];
  bool _isInitialized = false;

  // Search state and controller
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final bottomInset = WidgetsBinding.instance.platformDispatcher.views.first.viewInsets.bottom;
    if (bottomInset == 0 && _searchFocusNode.hasFocus) {
      _searchFocusNode.unfocus();
    }
  }

  Future<void> _fetchStaffList() async {
    final notifier = ref.read(staffManagementProvider.notifier);
    final user = ref.read(currentUserProvider);
    final registration = ref.read(branchRegistrationProvider);
    final isMultiBranch = registration.registeredBranches.length > 1;
    final isBrandOwner = user?.role.toLowerCase() == 'superadmin' || user?.role.toLowerCase() == 'admin';
    final isSuperAdmin = isBrandOwner && isMultiBranch;

    if (isSuperAdmin) {
      if (_selectedBranchTab == 'Tất cả') {
        try {
          final results = await Future.wait(
            _realBranches.map((b) => notifier.getStaffListForBranch(b.id))
          );
          final combined = results.expand((list) => list).toList();
          notifier.setStaffList(combined);
        } catch (e) {
          print('[StaffManagementPage] Error fetching staff for all branches: $e');
        }
      } else {
        final bId = _branchNameToId[_selectedBranchTab];
        if (bId != null) {
          await notifier.fetchStaffMembers(bId);
        }
      }
    } else {
      final bId = user?.branchId ?? registration.approvedFirstBranchId;
      if (bId != null && bId.isNotEmpty) {
        await notifier.fetchStaffMembers(bId);
      } else {
        if (_realBranches.isNotEmpty) {
          await notifier.fetchStaffMembers(_realBranches.first.id);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final registration = ref.watch(branchRegistrationProvider);
    final isMultiBranch = registration.registeredBranches.length > 1;
    final isBrandOwner = user?.role.toLowerCase() == 'superadmin' || user?.role.toLowerCase() == 'admin';

    // Chỉ hiển thị giao diện đa chi nhánh nếu là Chủ thương hiệu và có trên 1 chi nhánh thực tế
    final isSuperAdmin = isBrandOwner && isMultiBranch;

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
      adminBranch = registration.registeredBranches.first['branchName'] ?? 'Quận 1';
    } else if (_realBranches.isNotEmpty) {
      adminBranch = _realBranches.first.name;
    }

    final branchesAsyncValue = ref.watch(branchesFutureProvider);

    branchesAsyncValue.whenData((branches) {
      if (!_isInitialized) {
        _realBranches = branches;
        _branchOptions = branches.map((b) => b.name).toList();
        _branchNameToId = {for (var b in branches) b.name: b.id};
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
    if (isSuperAdmin) {
      if (_selectedBranchTab == 'Tất cả') {
        filteredList = rawStaffList;
      } else {
        filteredList = rawStaffList
            .where((m) => m.branchName == _selectedBranchTab)
            .toList();
      }
    } else {
      // Admin/Manager chỉ thấy nhân viên chi nhánh của mình (đã lọc ở API cấp backend)
      filteredList = rawStaffList;
    }

    // Lọc tiếp theo từ khóa tìm kiếm
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filteredList = filteredList.where((m) {
        return m.fullName.toLowerCase().contains(query) ||
            m.phone.contains(query);
      }).toList();
    }

    return Scaffold(
      backgroundColor: AppColors.bgMain,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isSuperAdmin
              ? 'Quản lý Nhân sự Toàn Chuỗi'
              : 'Quản lý Nhân sự Chi nhánh',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            if (isSuperAdmin) _buildBranchTabs(),

            // ─── Premium Search Bar ─────────────────────────────────────────────
            _buildSearchBar(isSuperAdmin),

            // ─── Staff List Directory ──────────────────────────────────────────
            Expanded(
              child: branchesAsyncValue.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Lỗi tải chi nhánh: $err')),
                data: (_) {
                  if (filteredList.isEmpty) {
                    return _buildEmptyState();
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final member = filteredList[index];
                      return _buildStaffCard(
                          member, isSuperAdmin, adminBranch);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // ─── FAB: Add new staff member ─────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openStaffDialog(null, isSuperAdmin, adminBranch),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, size: 20),
        label: Text(
          isBrandOwner ? 'Bổ nhiệm Quản lý/Nhân viên' : 'Thêm Nhân viên mới',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ─── Premium Search Bar UI ───────────────────────────────────────────────
  Widget _buildSearchBar(bool isSuperAdmin) {
    return Padding(
      key: const ValueKey('staff_search_bar_padding'),
      padding: EdgeInsets.fromLTRB(16, isSuperAdmin ? 10 : 28, 16, 12),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outlineVariant),
          boxShadow: const [
            BoxShadow(
              color: Color(0x05000000),
              blurRadius: 6,
              offset: Offset(0, 3),
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
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Tìm kiếm nhân viên',
            hintStyle:
                const TextStyle(color: AppColors.textTertiary, fontSize: 13),
            prefixIcon: const Icon(Icons.search_rounded,
                color: AppColors.textTertiary, size: 20),
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
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }



  // ─── SuperAdmin Lọc Branch Tabs UI ─────────────────────────────────────────
  Widget _buildBranchTabs() {
    final List<String> tabs = ['Tất cả', ..._branchOptions];
    return Container(
      height: 48,
      margin: const EdgeInsets.only(top: 14, bottom: 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final isSelected = _selectedBranchTab == tab;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                tab,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedBranchTab = tab;
                  });
                  _fetchStaffList();
                }
              },
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.bgSoft,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color:
                      isSelected ? AppColors.primary : AppColors.outlineVariant,
                  width: 1,
                ),
              ),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  // ─── Staff Card Item Widget ───────────────────────────────────────────────
  Widget _buildStaffCard(
      StaffMemberModel member, bool isSuperAdmin, String adminBranch) {
    Color badgeBgColor;
    Color badgeTextColor;
    String displayRole;

    switch (member.role) {
      case 'Admin':
        badgeBgColor = const Color(0xFFFFECEB);
        badgeTextColor = Colors.red.shade900;
        displayRole = 'Chủ thương hiệu (Admin)';
        break;
      case 'Manager':
        badgeBgColor = const Color(0xFFFFF2E6);
        badgeTextColor = Colors.orange.shade900;
        displayRole = 'Quản lý chi nhánh (Manager)';
        break;
      case 'Staff':
      default:
        badgeBgColor = const Color(0xFFEAF8EB);
        badgeTextColor = Colors.green.shade900;
        displayRole = 'Nhân viên phục vụ (Staff)';
    }

    final initials =
        member.fullName.trim().split(' ').last.substring(0, 1).toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Letter Avatar
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                initials,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info Detail
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          member.fullName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Branch Badge (Visible to SuperAdmin or for confirmation)
                      if (isSuperAdmin)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.bgSoft,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.outlineVariant),
                          ),
                          child: Text(
                            member.branchName,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textTertiary,
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
                        member.phone,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Role Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeBgColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      displayRole,
                      style: TextStyle(
                        color: badgeTextColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Actions (Edit/Delete)
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      color: AppColors.textSecondary, size: 20),
                  onPressed: () =>
                      _openStaffDialog(member, isSuperAdmin, adminBranch),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Colors.red, size: 20),
                  onPressed: () => _confirmDelete(member),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
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
      StaffMemberModel? existing, bool isSuperAdmin, String adminBranch) {
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
            isSuperAdmin: isSuperAdmin,
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
                  final bId = _branchNameToId[member.branchName] ?? ref.read(staffManagementProvider.notifier).activeBranchId;
                  if (bId != null) {
                    await ref
                        .read(staffManagementProvider.notifier)
                        .toggleStaffStatus(member.id, false);
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
                    message: 'Lỗi khi vô hiệu hóa: ${e.toString().replaceAll('Exception: ', '')}',
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
            decoration: BoxDecoration(
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
  final bool isSuperAdmin;
  final String adminBranch;
  final List<String> branchOptions;
  final Map<String, String> branchNameToId;
  final VoidCallback onSaveSuccess;

  const _StaffEditorSheetContent({
    this.existing,
    required this.isSuperAdmin,
    required this.adminBranch,
    required this.branchOptions,
    required this.branchNameToId,
    required this.onSaveSuccess,
  });

  @override
  ConsumerState<_StaffEditorSheetContent> createState() => _StaffEditorSheetContentState();
}

class _StaffEditorSheetContentState extends ConsumerState<_StaffEditorSheetContent> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late String _selectedRole;
  late String _selectedBranch;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.fullName ?? '');
    _phoneController = TextEditingController(text: widget.existing?.phone ?? '');
    
    _selectedRole = widget.existing?.role ?? 'Manager';
    if (_selectedRole == 'Admin') {
      _selectedRole = 'Manager';
    }

    _selectedBranch = widget.existing?.branchName ??
        (widget.isSuperAdmin ? widget.branchOptions[0] : widget.adminBranch);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return _KeyboardAvoidPadding(
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

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEdit
                      ? 'Chỉnh sửa thông tin'
                      : (widget.isSuperAdmin ? 'Bổ nhiệm Nhân sự mới' : 'Thêm Nhân viên mới'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
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
                  // 1. Full Name
                  const Text(
                    'Họ và tên nhân sự *',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    autofocus: true,
                    keyboardType: TextInputType.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'Nhập họ và tên...',
                      hintStyle: const TextStyle(color: AppColors.textPlaceholder, fontSize: 13),
                      prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.outlineVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.error, width: 1.0),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Vui lòng nhập họ tên';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 2. Phone
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
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'Nhập số điện thoại...',
                      hintStyle: const TextStyle(color: AppColors.textPlaceholder, fontSize: 13),
                      prefixIcon: const Icon(Icons.phone_iphone_rounded, color: AppColors.primary, size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.outlineVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.error, width: 1.0),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
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
                  const SizedBox(height: 16),

                  // 3. Branch selection dropdown (only for brand owner, lock to admin branch for standard admin)
                  if (widget.isSuperAdmin) ...[
                    const Text(
                      'Chi nhánh làm việc *',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedBranch,
                      dropdownColor: Colors.white,
                      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.storefront_outlined, color: AppColors.primary, size: 20),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.outlineVariant),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                      ),
                      items: widget.branchOptions.map((branch) {
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
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 4. Role choice chips
                  const Text(
                    'Phân vai trò / Quyền hạn *',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Quản lý chi nhánh', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        selected: _selectedRole == 'Manager',
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedRole = 'Manager');
                        },
                        selectedColor: Colors.orange.shade100,
                        backgroundColor: AppColors.bgSoft,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: _selectedRole == 'Manager' ? Colors.orange.shade400 : AppColors.outlineVariant)),
                        labelStyle: TextStyle(
                          color: _selectedRole == 'Manager' ? Colors.orange.shade900 : AppColors.textSecondary,
                        ),
                        showCheckmark: false,
                      ),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        label: const Text('Nhân viên phục vụ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        selected: _selectedRole == 'Staff',
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedRole = 'Staff');
                        },
                        selectedColor: Colors.green.shade100,
                        backgroundColor: AppColors.bgSoft,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: _selectedRole == 'Staff' ? Colors.green.shade400 : AppColors.outlineVariant)),
                        labelStyle: TextStyle(
                          color: _selectedRole == 'Staff' ? Colors.green.shade900 : AppColors.textSecondary,
                        ),
                        showCheckmark: false,
                      ),
                    ],
                  ),
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
                            side: const BorderSide(color: AppColors.outlineVariant),
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
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              final notifier = ref.read(staffManagementProvider.notifier);
                              final navigator = Navigator.of(context);
                              
                              try {
                                if (widget.existing == null) {
                                  final targetBranchId = widget.branchNameToId[_selectedBranch] ?? notifier.activeBranchId;
                                  
                                  final newMember = StaffMemberModel(
                                    id: '',
                                    fullName: _nameController.text.trim(),
                                    phone: _phoneController.text.trim(),
                                    role: _selectedRole,
                                    branchName: _selectedBranch,
                                    createdAt: DateTime.now().toIso8601String(),
                                  );
                                  await notifier.addStaffMember(newMember, targetBranchId: targetBranchId);
                                } else {
                                  final targetBranchId = widget.branchNameToId[_selectedBranch] ?? notifier.activeBranchId;
                                  
                                  final updated = widget.existing!.copyWith(
                                    fullName: _nameController.text.trim(),
                                    phone: _phoneController.text.trim(),
                                    role: _selectedRole,
                                    branchName: _selectedBranch,
                                  );
                                  await notifier.updateStaffMember(updated, targetBranchId: targetBranchId);
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
                                  message: 'Lỗi: ${e.toString().replaceAll('Exception: ', '')}',
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
                            isEdit ? 'Lưu Thay Đổi' : 'Thêm Nhân Sự',
                            style: const TextStyle(fontWeight: FontWeight.bold),
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
    );
  }
}

class _KeyboardAvoidPadding extends StatelessWidget {
  final Widget child;
  const _KeyboardAvoidPadding({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: child,
    );
  }
}

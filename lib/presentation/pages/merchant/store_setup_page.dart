import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import 'mock_store_detail_page.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../data/repositories/merchant_repository.dart';
import '../../../providers/branch_provider.dart';
import '../../../providers/branch_registration_provider.dart';

class StoreSetupPage extends ConsumerStatefulWidget {
  const StoreSetupPage({super.key});

  @override
  ConsumerState<StoreSetupPage> createState() => _StoreSetupPageState();
}

class _StoreSetupPageState extends ConsumerState<StoreSetupPage> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  late TextEditingController _nameController;
  late TextEditingController _hotlineController;

  // Focus Nodes
  late FocusNode _nameFocusNode;
  late FocusNode _hotlineFocusNode;

  // Selected values
  String _selectedCategory = 'Phở & Bún';
  String _storeStatus = 'active'; // 'active' | 'busy' | 'closed'
  TimeOfDay _openingTime = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _closingTime = const TimeOfDay(hour: 22, minute: 0);

  // Mock Images
  final List<String> _mockLogos = [
    'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=200&q=80', // Pho bowl
    'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=200&q=80', // Orange drink
    'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=200&q=80', // Healthy salad
  ];

  final List<String> _mockCovers = [
    'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800&q=80', // Cozy restaurant interior
    'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=800&q=80', // Cafe vibe
    'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&q=80', // Food assortment
  ];

  String? _customLogoPath;
  String? _customCoverPath;
  late String _selectedLogoUrl;
  late String _selectedCoverUrl;
  bool _isSaving = false;

  // Real data state
  bool _isLoadingData = true;
  String? _errorMessage;
  String? _branchId;

  @override
  void initState() {
    super.initState();
    // Default initial mock values (will be overwritten by API data if successful)
    _nameController = TextEditingController();
    _hotlineController = TextEditingController();

    _nameFocusNode = FocusNode();
    _hotlineFocusNode = FocusNode();

    _selectedLogoUrl = _mockLogos[0];
    _selectedCoverUrl = _mockCovers[0];

    // Load actual settings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBranchAndSettings();
    });
  }

  // Parse time string formatted as HH:mm:ss or HH:mm into TimeOfDay
  TimeOfDay _parseTimeString(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return const TimeOfDay(hour: 6, minute: 0);
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      print('[StoreSetupPage] Error parsing time string $timeStr: $e');
    }
    return const TimeOfDay(hour: 6, minute: 0);
  }

  Future<void> _loadBranchAndSettings() async {
    setState(() {
      _isLoadingData = true;
      _errorMessage = null;
    });

    try {
      // 1. Get branch ID. We try to read approvedFirstBranchId from the registration state first.
      var registrationData = ref.read(branchRegistrationProvider);
      if (registrationData.approvedFirstBranchId == null || registrationData.approvedFirstBranchId!.isEmpty) {
        try {
          await ref.read(branchRegistrationProvider.notifier).fetchApplicationStatus();
          registrationData = ref.read(branchRegistrationProvider);
        } catch (e) {
          print('[StoreSetupPage] Error fetching application status for branch ID: $e');
        }
      }

      _branchId = registrationData.approvedFirstBranchId;

      if (_branchId == null || _branchId!.isEmpty) {
        // Fallback: Fetch the list of branches from BranchRepository
        final branchRepo = ref.read(branchRepositoryProvider);
        final branches = await branchRepo.getBranches();
        
        if (branches.isEmpty) {
          throw Exception('Không tìm thấy chi nhánh nào để thiết lập. Vui lòng đăng ký chi nhánh trước.');
        }

        // Use the first branch
        final firstBranch = branches.first;
        _branchId = firstBranch.id;
      }

      // 2. Fetch settings for this branch
      final merchantRepo = MerchantRepository();
      final settings = await merchantRepo.getBranchSettings(_branchId!);

      // Support backend API envelopes (like settings['data'] or settings directly)
      final data = settings['data'] ?? settings;

      if (mounted) {
        setState(() {
          _nameController.text = data['name']?.toString() ?? '';
          _hotlineController.text = data['phone']?.toString() ?? '';
          
          final category = data['category']?.toString();
          const categories = ['Phở & Bún', 'Cơm Việt Nam', 'Đồ Ăn Vặt', 'Đồ Uống', 'Bánh Mì'];
          if (category != null && category.isNotEmpty) {
            if (categories.contains(category)) {
              _selectedCategory = category;
            } else {
              _selectedCategory = categories.first;
            }
          }

          final status = data['status']?.toString().toLowerCase();
          if (status == 'active' || status == 'busy' || status == 'closed') {
            _storeStatus = status!;
          }

          final logo = data['imageUrl']?.toString();
          if (logo != null && logo.isNotEmpty) {
            if (logo.startsWith('http') || File(logo).existsSync()) {
              _selectedLogoUrl = logo;
              _customLogoPath = logo;
            } else {
              _selectedLogoUrl = _mockLogos[0];
            }
          }

          final cover = data['coverImageUrl']?.toString();
          if (cover != null && cover.isNotEmpty) {
            if (cover.startsWith('http') || File(cover).existsSync()) {
              _selectedCoverUrl = cover;
              _customCoverPath = cover;
            } else {
              _selectedCoverUrl = _mockCovers[0];
            }
          }

          _openingTime = _parseTimeString(data['openingTime']?.toString());
          _closingTime = _parseTimeString(data['closingTime']?.toString());

          _isLoadingData = false;
        });
      }
    } catch (e) {
      print('[StoreSetupPage] Error loading branch settings: $e');
      if (mounted) {
        String errorText = e.toString().replaceAll('Exception: ', '');
        if (errorText.contains('outside current brand scope') || errorText.contains('outside current scope')) {
          errorText = 'Lỗi từ máy chủ: Chi nhánh này nằm ngoài phạm vi thương hiệu của tài khoản của bạn.\n\n'
              'Để thiết lập dữ liệu thật, hồ sơ đăng ký của bạn cần được phê duyệt bởi SuperAdmin trên hệ thống máy chủ (Backend), sau đó bạn cần đăng xuất và đăng nhập lại để nhận Access Token mới chứa quyền Admin và BrandId của bạn.';
        }
        setState(() {
          _errorMessage = errorText;
          _isLoadingData = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hotlineController.dispose();
    _nameFocusNode.dispose();
    _hotlineFocusNode.dispose();
    super.dispose();
  }

  // Format TimeOfDay to HH:mm
  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Choose Time helper
  Future<void> _selectTime(BuildContext context, bool isOpening) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isOpening ? _openingTime : _closingTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isOpening) {
          _openingTime = picked;
        } else {
          _closingTime = picked;
        }
      });
    }
  }

  // Pick image from phone gallery using ImagePicker
  Future<void> _pickImage({required bool isLogo}) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: isLogo ? 500 : 1200,
        maxHeight: isLogo ? 500 : 800,
        imageQuality: 85,
      );

      if (image == null) return;

      if (_branchId == null) {
        throw Exception('Không tìm thấy ID chi nhánh để tải ảnh lên.');
      }

      // Show uploading dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text('Đang tải ảnh lên...', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      );

      final merchantRepo = MerchantRepository();
      final uploadedUrl = await merchantRepo.uploadImage(
        image.path,
        'branches/$_branchId',
      );

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      setState(() {
        if (isLogo) {
          _customLogoPath = uploadedUrl;
          _selectedLogoUrl = uploadedUrl;
        } else {
          _customCoverPath = uploadedUrl;
          _selectedCoverUrl = uploadedUrl;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tải ảnh lên thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted) {
        try {
          Navigator.pop(context);
        } catch (_) {}
      }
      
      print('Error picking/uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải ảnh: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _formatTimeOfDayToAPI(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Submit / Save settings
  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    if (_branchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy ID chi nhánh để cập nhật.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final merchantRepo = MerchantRepository();
      
      final payload = {
        "name": _nameController.text.trim(),
        "phone": _hotlineController.text.trim(),
        "category": _selectedCategory,
        "imageUrl": _selectedLogoUrl,
        "coverImageUrl": _selectedCoverUrl,
        "openingTime": _formatTimeOfDayToAPI(_openingTime),
        "closingTime": _formatTimeOfDayToAPI(_closingTime),
        "status": _storeStatus,
      };

      await merchantRepo.updateBranchSettings(_branchId!, payload);

      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Lưu thiết lập cửa hàng thành công!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        context.pop();
      }
    } catch (e) {
      print('[StoreSetupPage] Error saving branch settings: $e');
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lưu thất bại: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Premium theme colors
    const primaryColor = AppColors.primary;

    return Scaffold(
      backgroundColor: AppColors.bgMain,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text(
          'Thiết lập cửa hàng',
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoadingData
          ? _buildLoadingIndicator()
          : (_errorMessage != null
              ? _buildErrorView()
              : Stack(
                  children: [
                    SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              // Safe padding at the bottom (chừa trống cho Save Button dính ở dưới)
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 16.0,
                bottom: 100.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===== 2. 🔥 LIVE MOCKUP CARD =====
                    _buildLiveMockupCard(),
                    const SizedBox(height: 12),
                    _buildLivePreviewButton(),
                    const SizedBox(height: 24),

                    // ===== 3. IMAGE PICKER SECTION =====
                    _buildSectionHeader(
                        'Hình ảnh thương hiệu', Icons.image_outlined),
                    const SizedBox(height: 12),
                    _buildLogoPicker(),
                    const SizedBox(height: 16),
                    _buildCoverPicker(),
                    const SizedBox(height: 24),

                    // ===== 4. GENERAL DETAILS =====
                    _buildSectionHeader(
                        'Thông tin cửa hàng', Icons.storefront_outlined),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _nameController,
                      focusNode: _nameFocusNode,
                      labelText: 'Tên cửa hàng / Chi nhánh',
                      hintText: 'Nhập tên cửa hàng của bạn',
                      prefixIcon: Icons.store_rounded,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập tên cửa hàng';
                        }
                        return null;
                      },
                      onChanged: (val) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    _buildCategoryDropdown(),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _hotlineController,
                      focusNode: _hotlineFocusNode,
                      labelText: 'Số điện thoại hotline',
                      hintText: 'Nhập hotline liên hệ',
                      prefixIcon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập số hotline';
                        }
                        if (value.trim().length < 9) {
                          return 'Số điện thoại không hợp lệ';
                        }
                        return null;
                      },
                      onChanged: (val) => setState(() {}),
                    ),
                    const SizedBox(height: 24),

                    // ===== 5. OPERATIONAL SETTINGS =====
                    _buildSectionHeader('Thời gian & Trạng thái hoạt động',
                        Icons.alarm_rounded),
                    const SizedBox(height: 12),
                    _buildOperatingHoursSection(),
                    const SizedBox(height: 16),
                    _buildStatusSelection(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),

          // ===== 6. SAVE BUTTON BAR (STICKY BOTTOM) =====
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Lưu thiết lập cửa hàng',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      )),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text(
            'Đang tải thiết lập cửa hàng...',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Đã xảy ra lỗi không xác định',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadBranchAndSettings,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Section Header helper
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // 🏪 Dynamic Live Mockup Card
  Widget _buildLiveMockupCard() {
    // Dynamic status calculations
    String statusText = 'Đang hoạt động';
    Color statusColor = AppColors.success;
    Color statusBgColor = AppColors.successContainer;

    if (_storeStatus == 'busy') {
      statusText = 'Quán đang bận';
      statusColor = AppColors.accent;
      statusBgColor = const Color(0xFFFFF7EC);
    } else if (_storeStatus == 'closed') {
      statusText = 'Tạm đóng cửa';
      statusColor = AppColors.error;
      statusBgColor = AppColors.errorContainer;
    }

    final storeName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : 'Tên cửa hàng chưa đặt';

    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background Cover Image
            Positioned.fill(
              child: _selectedCoverUrl.startsWith('http')
                  ? Image.network(
                      _selectedCoverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(color: AppColors.surfaceContainer);
                      },
                    )
                  : Image.file(
                      File(_selectedCoverUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(color: AppColors.surfaceContainer);
                      },
                    ),
            ),
            // Black gradient overlay for readable text
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.2),
                      Colors.black.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // Top Status Badge (floating)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: statusColor.withValues(alpha: 0.5), width: 1),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Mock Rating Indicator (floating left)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.star_rounded, color: AppColors.star, size: 14),
                    SizedBox(width: 4),
                    Text(
                      '4.8 (250+)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Content Layout
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Logo overlay inside card
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: _selectedLogoUrl.startsWith('http')
                          ? Image.network(
                              _selectedLogoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(color: AppColors.primaryContainer);
                              },
                            )
                          : Image.file(
                              File(_selectedLogoUrl),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(color: AppColors.primaryContainer);
                              },
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Shop text information
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          storeName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        // Category chip inside preview
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _selectedCategory,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded,
                                color: Colors.white70, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              '${_formatTimeOfDay(_openingTime)} - ${_formatTimeOfDay(_closingTime)}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.phone_rounded,
                                color: Colors.white70, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              _hotlineController.text.trim().isNotEmpty
                                  ? _hotlineController.text.trim()
                                  : 'Chưa nhập hotline',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Beautiful interactive Live Preview Button
  Widget _buildLivePreviewButton() {
    return Container(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MockStoreDetailPage(
                branchId: _branchId,
                storeName: _nameController.text.trim().isNotEmpty
                    ? _nameController.text.trim()
                    : 'Tên cửa hàng chưa đặt',
                logoUrl: _selectedLogoUrl,
                coverUrl: _selectedCoverUrl,
                category: _selectedCategory,
                hotline: _hotlineController.text.trim().isNotEmpty
                    ? _hotlineController.text.trim()
                    : 'Chưa nhập hotline',
                storeStatus: _storeStatus,
                openingTime: _formatTimeOfDay(_openingTime),
                closingTime: _formatTimeOfDay(_closingTime),
              ),
            ),
          );
        },
        icon: const Icon(Icons.fullscreen_rounded,
            size: 20, color: AppColors.primary),
        label: const Text(
          'Xem trước trang cửa hàng',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: AppColors.primary.withValues(alpha: 0.04),
          foregroundColor: AppColors.primary,
        ),
      ),
    );
  }

  // 🖼️ Logo selection horizontal slider with device upload support
  Widget _buildLogoPicker() {
    final hasCustomLogo = _customLogoPath != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn ảnh Đại diện / Logo',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              // 1. "Upload from Phone" Trigger Button
              GestureDetector(
                onTap: () => _pickImage(isLogo: true),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      style: BorderStyle.solid,
                      width: 1.5,
                    ),
                    color: AppColors.primary.withValues(alpha: 0.05),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo_outlined,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Tải lên',
                        style: TextStyle(
                          fontSize: 9,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // 2. Custom picked logo (if any)
              if (hasCustomLogo) ...[
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedLogoUrl = _customLogoPath!;
                    });
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _selectedLogoUrl == _customLogoPath
                            ? AppColors.primary
                            : AppColors.outlineVariant,
                        width: _selectedLogoUrl == _customLogoPath ? 3 : 1,
                      ),
                      boxShadow: _selectedLogoUrl == _customLogoPath
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 6,
                              )
                            ]
                          : null,
                    ),
                    child: ClipOval(
                      child: _customLogoPath!.startsWith('http')
                          ? Image.network(
                              _customLogoPath!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(color: AppColors.primaryContainer),
                            )
                          : Image.file(
                              File(_customLogoPath!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(color: AppColors.primaryContainer),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],

              // 3. Unsplash Mock Logos
              ...List.generate(_mockLogos.length, (index) {
                final logoUrl = _mockLogos[index];
                final isSelected = logoUrl == _selectedLogoUrl;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedLogoUrl = logoUrl;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.outlineVariant,
                        width: isSelected ? 3 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 6,
                              )
                            ]
                          : null,
                    ),
                    child: ClipOval(
                      child: Image.network(
                        logoUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  // 🖼️ Cover image selection horizontal slider with device upload support
  Widget _buildCoverPicker() {
    final hasCustomCover = _customCoverPath != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn ảnh bìa cửa hàng',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              // 1. "Upload from Phone" Trigger Button
              GestureDetector(
                onTap: () => _pickImage(isLogo: false),
                child: Container(
                  width: 100,
                  height: 55,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      style: BorderStyle.solid,
                      width: 1.5,
                    ),
                    color: AppColors.primary.withValues(alpha: 0.05),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Tải ảnh lên',
                        style: TextStyle(
                          fontSize: 9,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // 2. Custom picked cover (if any)
              if (hasCustomCover) ...[
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCoverUrl = _customCoverPath!;
                    });
                  },
                  child: Container(
                    width: 100,
                    height: 55,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _selectedCoverUrl == _customCoverPath
                            ? AppColors.primary
                            : AppColors.outlineVariant,
                        width: _selectedCoverUrl == _customCoverPath ? 3 : 1,
                      ),
                      boxShadow: _selectedCoverUrl == _customCoverPath
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 6,
                              )
                            ]
                          : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: _customCoverPath!.startsWith('http')
                          ? Image.network(
                              _customCoverPath!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(color: AppColors.surfaceContainer),
                            )
                          : Image.file(
                              File(_customCoverPath!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(color: AppColors.surfaceContainer),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],

              // 3. Unsplash Mock Covers
              ...List.generate(_mockCovers.length, (index) {
                final coverUrl = _mockCovers[index];
                final isSelected = coverUrl == _selectedCoverUrl;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCoverUrl = coverUrl;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 100,
                    height: 55,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.outlineVariant,
                        width: isSelected ? 3 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 6,
                              )
                            ]
                          : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: Image.network(
                        coverUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  // Form custom text field generator
  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    required void Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          onChanged: onChanged,
          validator: validator,
          style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: AppColors.textPlaceholder),
            prefixIcon:
                Icon(prefixIcon, color: AppColors.textSecondary, size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // Dropdown for categories
  Widget _buildCategoryDropdown() {
    final List<String> categories = [
      'Phở & Bún',
      'Cơm Việt Nam',
      'Đồ Ăn Vặt',
      'Đồ Uống',
      'Bánh Mì'
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lĩnh vực kinh doanh / Cuisine',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSecondary),
              style:
                  const TextStyle(fontSize: 15, color: AppColors.textPrimary),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                }
              },
              items: categories.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // Time Picker section selector
  Widget _buildOperatingHoursSection() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Giờ mở cửa',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => _selectTime(context, true),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatTimeOfDay(_openingTime),
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary),
                      ),
                      const Icon(Icons.access_time_rounded,
                          color: AppColors.primary, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Giờ đóng cửa',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => _selectTime(context, false),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatTimeOfDay(_closingTime),
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary),
                      ),
                      const Icon(Icons.access_time_rounded,
                          color: AppColors.primary, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Active / Holidays / Closed status switches
  Widget _buildStatusSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Trạng thái hoạt động tức thì',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildStatusChip('active', 'Đang bán', Icons.check_circle_rounded,
                AppColors.success),
            const SizedBox(width: 10),
            _buildStatusChip(
                'busy', 'Quán bận', Icons.warning_rounded, AppColors.accent),
            const SizedBox(width: 10),
            _buildStatusChip(
                'closed', 'Tạm đóng', Icons.cancel_rounded, AppColors.error),
          ],
        ),
      ],
    );
  }

  // Custom radio style status chips
  Widget _buildStatusChip(
      String statusVal, String label, IconData icon, Color color) {
    final isSelected = _storeStatus == statusVal;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _storeStatus = statusVal;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : AppColors.outlineVariant,
              width: isSelected ? 1.8 : 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? color : AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

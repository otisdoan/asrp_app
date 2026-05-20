import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';

/// Onboarding Survey — 5 screens for first-time users.
/// Collects food preferences, meal times, budget, priorities, and dietary needs.
/// Follows RULE: UI-only widgets, AppColors 100%, responsive.
class OnboardingSurveyPage extends StatefulWidget {
  const OnboardingSurveyPage({super.key});

  @override
  State<OnboardingSurveyPage> createState() => _OnboardingSurveyPageState();
}

class _OnboardingSurveyPageState extends State<OnboardingSurveyPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Survey data
  final List<String> _selectedFoods = [];
  final List<String> _selectedMealTimes = [];
  String? _selectedBudget;
  final List<String> _selectedPriorities = [];
  final List<String> _selectedDiets = [];

  // Survey questions
  static const _questions = [
    {
      'title': 'Bạn thích món gì nhất?',
      'subtitle': 'Chọn các món bạn yêu thích để chúng tôi gợi ý tốt hơn',
      'multiSelect': true,
      'tags': ['Cơm', 'Bún', 'Phở', 'Trà sữa', 'Gà rán', 'BBQ', 'Hải sản', 'Đồ ăn vặt', 'Healthy', 'Chay', 'Fast food', 'Cafe', 'Bánh ngọt', 'Sushi', 'Lẩu', 'Nướng'],
      'icons': ['🍚', '🍜', '🍲', '🧋', '🍗', '🥩', '🦐', '🍿', '🥗', '🥬', '🍔', '☕', '🍰', '🍣', '🫕', '🔥'],
    },
    {
      'title': 'Bạn thường ăn vào lúc nào?',
      'subtitle': 'Giúp chúng tôi gợi ý đúng thời điểm',
      'multiSelect': true,
      'tags': ['Bữa sáng', 'Bữa trưa', 'Bữa tối', 'Ăn khuya', 'Cafe chiều'],
      'icons': ['🌅', '☀️', '🌙', '🌃', '🍵'],
    },
    {
      'title': 'Mức giá bạn thường order?',
      'subtitle': 'Chọn mức giá phù hợp với bạn',
      'multiSelect': false,
      'tags': ['Dưới 50k', '50k - 100k', '100k - 200k', 'Trên 200k'],
      'icons': ['💰', '💵', '💳', '💎'],
    },
    {
      'title': 'Điều bạn quan tâm nhất\nkhi đặt đồ ăn?',
      'subtitle': 'Chọn những yếu tố quan trọng với bạn',
      'multiSelect': true,
      'tags': ['Giao nhanh', 'Giá rẻ', 'Nhiều voucher', 'Ngon', 'Healthy', 'Đóng gói đẹp', 'Quán nổi tiếng'],
      'icons': ['⚡', '🏷️', '🎟️', '😋', '🥗', '📦', '⭐'],
    },
    {
      'title': 'Bạn có chế độ ăn\nđặc biệt không?',
      'subtitle': 'Giúp chúng tôi lọc món phù hợp',
      'multiSelect': true,
      'tags': ['Eat clean', 'Keto', 'Vegan', 'Vegetarian', 'Ít đường', 'Ít cay', 'Không hành', 'Không có'],
      'icons': ['🥦', '🥑', '🌱', '🥕', '🚫🍬', '🌶️', '🧅', '✅'],
    },
  ];

  List<String> _getSelectedForPage(int page) {
    switch (page) {
      case 0: return _selectedFoods;
      case 1: return _selectedMealTimes;
      case 2: return _selectedBudget != null ? [_selectedBudget!] : [];
      case 3: return _selectedPriorities;
      case 4: return _selectedDiets;
      default: return [];
    }
  }

  void _toggleTag(int page, String tag) {
    setState(() {
      final isMultiSelect = _questions[page]['multiSelect'] as bool;
      if (page == 2) {
        // Single select for budget
        _selectedBudget = _selectedBudget == tag ? null : tag;
      } else {
        final list = _getSelectedForPage(page);
        if (isMultiSelect) {
          if (list.contains(tag)) {
            list.remove(tag);
          } else {
            list.add(tag);
          }
        }
      }
    });
  }

  bool _isSelected(int page, String tag) {
    if (page == 2) return _selectedBudget == tag;
    return _getSelectedForPage(page).contains(tag);
  }

  void _nextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeSurvey();
    }
  }

  void _skipPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeSurvey();
    }
  }

  Future<void> _completeSurvey() async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'onboarding_completed', value: 'true');
    if (mounted) context.go(AppConstants.routeHome);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Top Bar ─────────────────────────────────────────
            _buildTopBar(),
            // ─── Progress Indicator ──────────────────────────────
            _buildProgressBar(),
            // ─── Page Content ────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: 5,
                itemBuilder: (context, index) => _buildSurveyPage(index),
              ),
            ),
            // ─── Bottom Button ───────────────────────────────────
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  // ─── Top Bar ───────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back or step indicator
          if (_currentPage > 0)
            GestureDetector(
              onTap: () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                );
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.bgSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back, size: 18, color: AppColors.textPrimary),
              ),
            )
          else
            const SizedBox(width: 36),
          // Step counter
          Text(
            '${_currentPage + 1}/5',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          // Skip button
          GestureDetector(
            onTap: _skipPage,
            child: const Text(
              'Bỏ qua',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Progress Bar ──────────────────────────────────────────────────────
  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: List.generate(5, (index) {
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < 4 ? 6 : 0),
              decoration: BoxDecoration(
                color: index <= _currentPage ? AppColors.primary : AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─── Survey Page ───────────────────────────────────────────────────────
  Widget _buildSurveyPage(int pageIndex) {
    final question = _questions[pageIndex];
    final tags = question['tags'] as List<String>;
    final icons = question['icons'] as List<String>;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question title
          Text(
            question['title'] as String,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            question['subtitle'] as String,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 28),
          // Tags grid
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(tags.length, (index) {
              final tag = tags[index];
              final icon = icons[index];
              final selected = _isSelected(pageIndex, tag);
              return _buildTag(
                label: tag,
                icon: icon,
                selected: selected,
                onTap: () => _toggleTag(pageIndex, tag),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ─── Tag Chip ──────────────────────────────────────────────────────────
  Widget _buildTag({
    required String label,
    required String icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryContainer : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 6),
              const Icon(Icons.check_circle, size: 16, color: AppColors.primary),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Bottom Button ─────────────────────────────────────────────────────
  Widget _buildBottomButton() {
    final hasSelection = _getSelectedForPage(_currentPage).isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: hasSelection ? _nextPage : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            disabledBackgroundColor: AppColors.outlineVariant,
            disabledForegroundColor: AppColors.textTertiary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: Text(
            _currentPage < 4 ? 'Tiếp tục' : 'Hoàn thành',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

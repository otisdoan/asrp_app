import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class HomeBottomNavigationBar extends StatelessWidget {
  final int currentTabIndex;
  final ValueChanged<int> onTabTapped;

  const HomeBottomNavigationBar({
    super.key,
    required this.currentTabIndex,
    required this.onTabTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home_rounded, 'Trang chủ'),
            _buildNavItem(
                1, Icons.account_balance_wallet_outlined, 'Thanh toán'),
            _buildNavItem(2, Icons.receipt_long_outlined, 'Đơn hàng'),
            _buildNavItem(3, Icons.chat_bubble_outline_rounded, 'Tin nhắn',
                badgeCount: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label,
      {int badgeCount = 0}) {
    final isSelected = currentTabIndex == index;
    const activeColor = AppColors.primary;
    const inactiveColor = AppColors.textSecondary;

    return InkWell(
      onTap: () => onTabTapped(index),
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: isSelected ? activeColor : inactiveColor,
                  size: 24,
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

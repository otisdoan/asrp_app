import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Payment Page — shows payment options and recent transactions.
/// Follows RULE: UI-only, uses AppColors, responsive.
class PaymentPage extends StatelessWidget {
  const PaymentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header Section (Purple gradient) ─────────────────
          _buildHeader(),

          // ─── Add Card Button ──────────────────────────────────
          _buildAddCardButton(),

          // ─── Recent Transactions ──────────────────────────────
          _buildRecentTransactions(),
        ],
      ),
    );
  }

  // ─── Purple Gradient Header ────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryActive, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Title
            const Text(
              'Thanh toán',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.onPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Thanh toán hằng ngày đơn giản,\nlinh hoạt',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.onPrimary,
                height: 1.4,
              ),
            ),
          const SizedBox(height: 20),
          // Card — Thêm thẻ
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.credit_card, color: AppColors.onPrimary, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thêm thẻ',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Thanh toán không tiền mặt với thẻ tín dụng hoặ...',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.onPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

  // ─── Add Card Button ───────────────────────────────────────────────────
  Widget _buildAddCardButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.credit_card, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text(
              'Add Card',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Recent Transactions ───────────────────────────────────────────────
  Widget _buildRecentTransactions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          const Text(
            'Giao dịch gần đây',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 40),
          // Empty state
          Center(
            child: Column(
              children: [
                // Document illustration
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.bgSoft,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.receipt_long_outlined,
                    size: 48,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Không có hoạt động nào gần đây.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {},
                  child: const Text(
                    'Xem các giao dịch trước đó',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
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
}

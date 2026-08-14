import 'package:intl/intl.dart';

class FormatUtils {
  FormatUtils._();

  static final NumberFormat _currencyFormat = NumberFormat('#,##0', 'vi_VN');

  /// Format number to Vietnamese currency: 95000 → "95,000đ"
  static String formatCurrency(num amount) {
    return '${_currencyFormat.format(amount)}đ';
  }

  /// Format currency with ₫ sign: 95000 → "95,000 ₫"
  static String formatCurrencySign(num amount) {
    return '${_currencyFormat.format(amount)} ₫';
  }

  /// Format stars: 4 → "★★★★☆"
  static String formatStars(int rating, {int max = 5}) {
    final filled = '★' * rating.clamp(0, max);
    final empty = '☆' * (max - rating.clamp(0, max));
    return '$filled$empty';
  }

  /// Format decimal rating: 4.7 → "★★★★★ (4.7)"
  static String formatRating(double rating) {
    return '${formatStars(rating.round())} (${rating.toStringAsFixed(1)})';
  }

  /// Format compact amount with dynamic units (đ, k, M, B):
  /// 450 → "450đ" | 46000 → "46k" | 1500000 → "1.5M" | 1200000000 → "1.2B"
  static String formatCompactAmount(num amount) {
    final absAmount = amount.abs();
    if (absAmount >= 1000000000) {
      final b = amount / 1000000000.0;
      return '${b.toStringAsFixed(b % 1 == 0 ? 0 : 1)}B';
    } else if (absAmount >= 1000000) {
      final m = amount / 1000000.0;
      return '${m.toStringAsFixed(m % 1 == 0 ? 0 : 1)}M';
    } else if (absAmount >= 1000) {
      final k = amount / 1000.0;
      return '${k.toStringAsFixed(k % 1 == 0 ? 0 : 1)}k';
    } else {
      return '${amount.toInt()}đ';
    }
  }

  /// Format count: 1240 → "1,240"
  static String formatCount(int count) {
    return _currencyFormat.format(count);
  }

  /// Format OTP countdown: 180 → "3:00"
  static String formatCountdown(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(1, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
